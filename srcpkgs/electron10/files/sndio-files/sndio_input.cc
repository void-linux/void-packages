// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/bind.h"
#include "base/logging.h"
#include "base/macros.h"
#include "media/base/audio_timestamp_helper.h"
#include "media/audio/openbsd/audio_manager_openbsd.h"
#include "media/audio/audio_manager.h"
#include "media/audio/sndio/sndio_input.h"

namespace media {

static const SampleFormat kSampleFormat = kSampleFormatS16;

void SndioAudioInputStream::OnMoveCallback(void *arg, int delta)
{
  SndioAudioInputStream* self = static_cast<SndioAudioInputStream*>(arg);

  self->hw_delay += delta;
}

void *SndioAudioInputStream::ThreadEntry(void *arg) {
  SndioAudioInputStream* self = static_cast<SndioAudioInputStream*>(arg);

  self->ThreadLoop();
  return NULL;
}

SndioAudioInputStream::SndioAudioInputStream(AudioManagerBase* manager,
                                             const std::string& device_name,
                                             const AudioParameters& params)
    : manager(manager),
      params(params),
      audio_bus(AudioBus::Create(params)),
      state(kClosed) {
}

SndioAudioInputStream::~SndioAudioInputStream() {
  if (state != kClosed)
    Close();
}

bool SndioAudioInputStream::Open() {
  struct sio_par par;
  int sig;

  if (state != kClosed)
    return false;

  if (params.format() != AudioParameters::AUDIO_PCM_LINEAR &&
      params.format() != AudioParameters::AUDIO_PCM_LOW_LATENCY) {
    LOG(WARNING) << "Unsupported audio format.";
    return false;
  }

  sio_initpar(&par);
  par.rate = params.sample_rate();
  par.rchan = params.channels();
  par.bits = SampleFormatToBitsPerChannel(kSampleFormat);
  par.bps = par.bits / 8;
  par.sig = sig = par.bits != 8 ? 1 : 0;
  par.le = SIO_LE_NATIVE;
  par.appbufsz = params.frames_per_buffer();

  hdl = sio_open(SIO_DEVANY, SIO_REC, 0);

  if (hdl == NULL) {
    LOG(ERROR) << "Couldn't open audio device.";
    return false;
  }

  if (!sio_setpar(hdl, &par) || !sio_getpar(hdl, &par)) {
    LOG(ERROR) << "Couldn't set audio parameters.";
    goto bad_close;
  }

  if (par.rate  != (unsigned int)params.sample_rate() ||
      par.rchan != (unsigned int)params.channels() ||
      par.bits  != (unsigned int)SampleFormatToBitsPerChannel(kSampleFormat) ||
      par.sig   != (unsigned int)sig ||
      (par.bps > 1 && par.le != SIO_LE_NATIVE) ||
      (par.bits != par.bps * 8)) {
    LOG(ERROR) << "Unsupported audio parameters.";
    goto bad_close;
  }
  state = kStopped;
  buffer = new char[audio_bus->frames() * params.GetBytesPerFrame(kSampleFormat)];
  sio_onmove(hdl, &OnMoveCallback, this);
  return true;
bad_close:
  sio_close(hdl);
  return false;
}

void SndioAudioInputStream::Start(AudioInputCallback* cb) {

  StartAgc();

  state = kRunning;
  hw_delay = 0;
  callback = cb;
  sio_start(hdl);
  if (pthread_create(&thread, NULL, &ThreadEntry, this) != 0) {
    LOG(ERROR) << "Failed to create real-time thread for recording.";
    sio_stop(hdl);
    state = kStopped;
  }
}

void SndioAudioInputStream::Stop() {

  if (state == kStopped)
    return;

  state = kStopWait;
  pthread_join(thread, NULL);
  sio_stop(hdl);
  state = kStopped;

  StopAgc();
}

void SndioAudioInputStream::Close() {

  if (state == kClosed)
    return;

  if (state == kRunning)
    Stop();

  state = kClosed;
  delete [] buffer;
  sio_close(hdl);

  manager->ReleaseInputStream(this);
}

double SndioAudioInputStream::GetMaxVolume() {
  // Not supported
  return 0.0;
}

void SndioAudioInputStream::SetVolume(double volume) {
  // Not supported. Do nothing.
}

double SndioAudioInputStream::GetVolume() {
  // Not supported.
  return 0.0;
}

bool SndioAudioInputStream::IsMuted() {
  // Not supported.
  return false;
}

void SndioAudioInputStream::SetOutputDeviceForAec(
    const std::string& output_device_id) {
  // Not supported.
}

void SndioAudioInputStream::ThreadLoop(void) {
  size_t todo, n;
  char *data;
  unsigned int nframes;
  double normalized_volume = 0.0;

  nframes = audio_bus->frames();

  while (state == kRunning && !sio_eof(hdl)) {

    GetAgcVolume(&normalized_volume);

    // read one block
    todo = nframes * params.GetBytesPerFrame(kSampleFormat);
    data = buffer;
    while (todo > 0) {
      n = sio_read(hdl, data, todo);
      if (n == 0)
        return;	// unrecoverable I/O error
      todo -= n;
      data += n;
    }
    hw_delay -= nframes;

    // convert frames count to TimeDelta
    const base::TimeDelta delay = AudioTimestampHelper::FramesToTime(hw_delay,
      params.sample_rate());

    // push into bus
    audio_bus->FromInterleaved(buffer, nframes, SampleFormatToBytesPerChannel(kSampleFormat));

    // invoke callback
    callback->OnData(audio_bus.get(), base::TimeTicks::Now() - delay, 1.);
  }
}

}  // namespace media
