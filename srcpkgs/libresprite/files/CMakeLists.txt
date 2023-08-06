cmake_minimum_required(VERSION 3.4)

project(generator C CXX)

set(BUILD_SHARED_LIBS off)

set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

set(MODP_B64_DIR        ${CMAKE_SOURCE_DIR}/third_party/modp_b64)

set(LIBRARY_OUTPUT_PATH ${CMAKE_BINARY_DIR}/lib)

add_definitions(-DNDEBUG)

find_library(TINYXML_LIBRARY NAMES tinyxml)
find_path(TINYXML_INCLUDE_DIR NAMES tinyxml.h)
include_directories(${TINYXML_INCLUDE_DIR})

add_subdirectory(src)

add_subdirectory(third_party)
