project(tgvoip)

option(ENABLE_PULSEAUDIO "Enable pulseaudio" ON)

add_subdirectory("${PROJECT_SOURCE_DIR}/webrtc_dsp/webrtc")

find_package(PkgConfig REQUIRED)
pkg_check_modules(OPUS REQUIRED opus)

file(GLOB TGVOIP_SOURCE_FILES
	*.cpp
	audio/*.cpp
	os/linux/*.cpp
	os/posix/*.cpp
)
file(GLOB TGVOIP_EXTRA_FILES
	audio/AudioIOCallback.cpp
	BufferInputStream.cpp
	BufferOutputStream.cpp
	BufferPool.cpp
)
list(REMOVE_ITEM TGVOIP_SOURCE_FILES ${TGVOIP_EXTRA_FILES})
set(TGVOIP_COMPILE_DEFINITIONS TGVOIP_USE_DESKTOP_DSP)

if(ENABLE_PULSEAUDIO)
	pkg_check_modules(LIBPULSE REQUIRED libpulse)
else()
	file(GLOB PULSEAUDIO_SOURCE_FILES
		os/linux/AudioInputPulse.cpp
		os/linux/AudioOutputPulse.cpp
		os/linux/PulseAudioLoader.cpp
	)
	list(REMOVE_ITEM TGVOIP_SOURCE_FILES ${PULSEAUDIO_SOURCE_FILES})
	list(APPEND TGVOIP_COMPILE_DEFINITIONS WITHOUT_PULSE)
endif()

add_library(${PROJECT_NAME} STATIC ${TGVOIP_SOURCE_FILES} $<TARGET_OBJECTS:webrtc>)

target_compile_definitions(${PROJECT_NAME} PUBLIC ${TGVOIP_COMPILE_DEFINITIONS})
target_include_directories(${PROJECT_NAME} PUBLIC
	"${OPUS_INCLUDE_DIRS}"
	"${CMAKE_CURRENT_LIST_DIR}/webrtc_dsp"
	"${CMAKE_CURRENT_LIST_DIR}/webrtc_dsp/webrtc"
)
target_link_libraries(${PROJECT_NAME} dl ${OPUS_LIBRARIES})
