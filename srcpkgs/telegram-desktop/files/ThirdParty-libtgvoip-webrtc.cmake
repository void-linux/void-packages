project(webrtc)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

list(APPEND WEBRTC_C_SOURCE_FILES
	"common_audio/fft4g.c"
	"common_audio/ring_buffer.c"
	"common_audio/signal_processing/auto_corr_to_refl_coef.c"
	"common_audio/signal_processing/auto_correlation.c"
	"common_audio/signal_processing/complex_bit_reverse.c"
	"common_audio/signal_processing/complex_fft.c"
	"common_audio/signal_processing/copy_set_operations.c"
	"common_audio/signal_processing/cross_correlation.c"
	"common_audio/signal_processing/division_operations.c"
	"common_audio/signal_processing/dot_product_with_scale.c"
	"common_audio/signal_processing/downsample_fast.c"
	"common_audio/signal_processing/energy.c"
	"common_audio/signal_processing/filter_ar.c"
	"common_audio/signal_processing/filter_ar_fast_q12.c"
	"common_audio/signal_processing/filter_ma_fast_q12.c"
	"common_audio/signal_processing/get_hanning_window.c"
	"common_audio/signal_processing/get_scaling_square.c"
	"common_audio/signal_processing/ilbc_specific_functions.c"
	"common_audio/signal_processing/levinson_durbin.c"
	"common_audio/signal_processing/lpc_to_refl_coef.c"
	"common_audio/signal_processing/min_max_operations.c"
	"common_audio/signal_processing/randomization_functions.c"
	"common_audio/signal_processing/real_fft.c"
	"common_audio/signal_processing/refl_coef_to_lpc.c"
	"common_audio/signal_processing/resample.c"
	"common_audio/signal_processing/resample_48khz.c"
	"common_audio/signal_processing/resample_by_2.c"
	"common_audio/signal_processing/resample_by_2_internal.c"
	"common_audio/signal_processing/resample_fractional.c"
	"common_audio/signal_processing/spl_init.c"
	"common_audio/signal_processing/spl_inl.c"
	"common_audio/signal_processing/spl_sqrt.c"
	"common_audio/signal_processing/spl_sqrt_floor.c"
	"common_audio/signal_processing/splitting_filter_impl.c"
	"common_audio/signal_processing/sqrt_of_one_minus_x_squared.c"
	"common_audio/signal_processing/vector_scaling_operations.c"
	"modules/audio_processing/agc/legacy/analog_agc.c"
	"modules/audio_processing/agc/legacy/digital_agc.c"
	"modules/audio_processing/ns/noise_suppression.c"
	"modules/audio_processing/ns/noise_suppression_x.c"
	"modules/audio_processing/ns/ns_core.c"
	"modules/audio_processing/ns/nsx_core.c"
	"modules/audio_processing/ns/nsx_core_c.c"
)

list(APPEND WEBRTC_CXX_SOURCE_FILES
	"base/checks.cc"
	"base/stringutils.cc"
	"common_audio/audio_util.cc"
	"common_audio/channel_buffer.cc"
	"common_audio/sparse_fir_filter.cc"
	"common_audio/wav_file.cc"
	"common_audio/wav_header.cc"
	"modules/audio_processing/splitting_filter.cc"
	"modules/audio_processing/three_band_filter_bank.cc"
	"modules/audio_processing/aec/aec_core.cc"
	"modules/audio_processing/aec/aec_core_sse2.cc"
	"modules/audio_processing/aec/aec_resampler.cc"
	"modules/audio_processing/aec/echo_cancellation.cc"
	"modules/audio_processing/aecm/aecm_core.cc"
	"modules/audio_processing/aecm/aecm_core_c.cc"
	"modules/audio_processing/aecm/echo_control_mobile.cc"
	"modules/audio_processing/logging/apm_data_dumper.cc"
	"modules/audio_processing/splitting_filter.cc"
	"modules/audio_processing/three_band_filter_bank.cc"
	"modules/audio_processing/utility/block_mean_calculator.cc"
	"modules/audio_processing/utility/delay_estimator.cc"
	"modules/audio_processing/utility/delay_estimator_wrapper.cc"
	"modules/audio_processing/utility/ooura_fft.cc"
	"modules/audio_processing/utility/ooura_fft_sse2.cc"
	"system_wrappers/source/cpu_features.cc"
)

add_library(${PROJECT_NAME} OBJECT ${WEBRTC_C_SOURCE_FILES} ${WEBRTC_CXX_SOURCE_FILES})

target_compile_definitions(${PROJECT_NAME} PUBLIC
	WEBRTC_APM_DEBUG_DUMP=0
	WEBRTC_POSIX
)

if( "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "i686" )
	set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msse2")
endif( "${CMAKE_SYSTEM_PROCESSOR}" STREQUAL "i686" )

# TODO: drop include dirs with latest webrtc
target_include_directories(${PROJECT_NAME} PUBLIC
	"${CMAKE_CURRENT_LIST_DIR}/.."
)
