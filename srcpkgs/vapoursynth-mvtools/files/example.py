import vapoursynth as vs

# see http://avisynth.org.ru/mvtools/mvtools2.html
# these configs will have around 75% usage with an FX-8350

def main():
    # don't interpolate if input is close to 60fps anyway
    if container_fps > 59:
        video_in.set_output()
        return

    # basic config
    config = {
            'blksize': 16,
            'chroma': True,
            'search': 4,
            'searchparam': 4,
            }
    recalcconfig = {
            'blksize': 8,
            'chroma': True,
            'search': 5,
            'searchparam': 2,
            }

    # use higher quality on 720p or lower
    if video_in.width * video_in.height <= 1280*720:
        config.update({
            'search': 5,
            'searchparam': 16,
            'blksize': 32,
            'badsad': 1000,
            'badrange': 32,
            'divide': 2,
            'overlap': 8,
            })
        recalcconfig.update({
            'search': 3,
            'blksize': 16,
            'overlap': 8,
            'dct': 8,
            })

    interpolate(config, recalcconfig)

# first pass
def analyse(sup, config):
    core = vs.get_core()
    bvec = core.mv.Analyse(sup, isb=True, **config)
    fvec = core.mv.Analyse(sup, isb=False, **config)
    return bvec, fvec

# optional second pass
def recalculate(sup, bvec, fvec, config):
    core = vs.get_core()
    bvec = core.mv.Recalculate(sup, bvec, **config)
    fvec = core.mv.Recalculate(sup, fvec, **config)
    return bvec, fvec

def interpolate(config, recalcconfig=None):
    core = vs.get_core()
    clip = video_in

    # Interpolating to fps higher than 60 is too CPU-expensive
    # Use interpolation from opengl video output
    dst_fps = display_fps
    while (dst_fps > 60):
        dst_fps /= 2

    src_fps_num = int(container_fps * 1e8)
    src_fps_den = int(1e8)
    dst_fps_num = int(dst_fps * 1e4)
    dst_fps_den = int(1e4)

    # Needed because clip FPS is missing
    clip = core.std.AssumeFPS(clip, fpsnum = src_fps_num, fpsden = src_fps_den)
    print("Reflowing from ",src_fps_num/src_fps_den," fps to ",dst_fps_num/dst_fps_den," fps.")

    pad = config.get('blksize',  8)
    sup  = core.mv.Super(clip, pel=1, hpad=pad, vpad=pad)
    bvec, fvec = analyse(sup, config)
    if recalcconfig:
        bvec, fvec = recalculate(sup, bvec, fvec, recalcconfig)
    clip = core.mv.FlowFPS(clip, sup, bvec, fvec, num=dst_fps_num, den=dst_fps_den, thscd2=90)

    clip.set_output()

if __name__ == '__vapoursynth__':
    main()
