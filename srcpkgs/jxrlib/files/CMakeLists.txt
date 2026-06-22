cmake_minimum_required(VERSION 3.5)
project(jxrlib C CXX)

set(JXRLIB_MAJOR 0)
set(JXRLIB_MINOR 0)

set(JXRLIB_LIB_VERSION ${JXRLIB_MAJOR}.${JXRLIB_MINOR}.0)
set(JXRLIB_SO_VERSION ${JXRLIB_MAJOR})

include(TestBigEndian)
test_big_endian(ISBIGENDIAN)
if(ISBIGENDIAN)
  set(DEF_ENDIAN -D_BIG__ENDIAN_)
endif()

add_definitions(-D__ANSI__ -DDISABLE_PERF_MEASUREMENT ${DEF_ENDIAN})

include_directories(
  common/include
  image/sys
  jxrgluelib
  jxrtestlib
)

# JXR Library
file(GLOB jpegxr_SRC image/sys/*.c image/decode/*.c image/encode/*.c)
file(GLOB jpegxr_HDR image/sys/*.h image/decode/*.h image/encode/*.h)

add_library(jpegxr SHARED ${jpegxr_SRC} ${jpegxr_HDR})
set_target_properties(jpegxr PROPERTIES VERSION ${JXRLIB_LIB_VERSION} SOVERSION ${JXRLIB_SO_VERSION})

install(TARGETS jpegxr
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib${LIB_SUFFIX}
  ARCHIVE DESTINATION lib${LIB_SUFFIX}
)

# JXR-GLUE Library
file(GLOB jxrglue_SRC jxrgluelib/*.c jxrtestlib/*.c)
file(GLOB jxrglue_HDR jxrgluelib/*.h jxrtestlib/*.h)

add_library(jxrglue SHARED ${jxrglue_SRC} ${jxrglue_HDR})
set_target_properties(jxrglue PROPERTIES VERSION ${JXRLIB_LIB_VERSION} SOVERSION ${JXRLIB_SO_VERSION})
target_link_libraries(jxrglue jpegxr m)

install(TARGETS jxrglue
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib${LIB_SUFFIX}
  ARCHIVE DESTINATION lib${LIB_SUFFIX}
)

# JxrEncApp Executable
add_executable(JxrEncApp jxrencoderdecoder/JxrEncApp.c)
target_link_libraries(JxrEncApp jxrglue)
install(TARGETS JxrEncApp RUNTIME DESTINATION bin)

# JxrDecApp Executable
add_executable(JxrDecApp jxrencoderdecoder/JxrDecApp.c)
target_link_libraries(JxrDecApp jxrglue)
install(TARGETS JxrDecApp RUNTIME DESTINATION bin)

# Headers
install(FILES jxrgluelib/JXRGlue.h jxrgluelib/JXRMeta.h jxrgluelib/JXRVersion.h jxrtestlib/JXRTest.h image/sys/windowsmediaphoto.h
  DESTINATION include/jxrlib
)
install(DIRECTORY common/include/ DESTINATION include/jxrlib
  FILES_MATCHING PATTERN "*.h"
)

# Generate pkgconfig file
include(JoinPaths.cmake)
join_paths(JXRLIB_PKGCONF_LIBDIR "\${prefix}" "${JXRLIB_INSTALL_LIBDIR}")
join_paths(JXRLIB_PKGCONF_INCLUDEDIR "\${prefix}" "${JXRLIB_INSTALL_INCLUDEDIR}")
configure_file(
    "${PROJECT_SOURCE_DIR}/libjxr.pc.in"
    ${PROJECT_BINARY_DIR}/jxrlib.pc
    @ONLY
)
install(
    FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.pc
    DESTINATION lib${LIB_SUFFIX}/pkgconfig
)
