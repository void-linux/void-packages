cmake_minimum_required(VERSION 3.8)

project(TelegramCodegen)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt5 REQUIRED Core Gui)

set(TELEGRAM_SOURCES_DIR ${CMAKE_SOURCE_DIR}/../SourceFiles)
include_directories(${TELEGRAM_SOURCES_DIR})

file(GLOB CODEGEN_COMMON_SOURCES
	${TELEGRAM_SOURCES_DIR}/codegen/common/*.h
	${TELEGRAM_SOURCES_DIR}/codegen/common/*.cpp
)

add_library(codegen_common OBJECT ${CODEGEN_COMMON_SOURCES})
target_include_directories(codegen_common PUBLIC $<TARGET_PROPERTY:Qt5::Core,INTERFACE_INCLUDE_DIRECTORIES>)
target_compile_options(codegen_common PUBLIC $<TARGET_PROPERTY:Qt5::Core,INTERFACE_COMPILE_OPTIONS>)

foreach(TOOL emoji lang numbers style)
	file(GLOB CODEGEN_${TOOL}_SOURCES
		${TELEGRAM_SOURCES_DIR}/codegen/${TOOL}/*.h
		${TELEGRAM_SOURCES_DIR}/codegen/${TOOL}/*.cpp
	)

	add_executable(codegen_${TOOL} ${CODEGEN_${TOOL}_SOURCES} $<TARGET_OBJECTS:codegen_common>)
	target_link_libraries(codegen_${TOOL} Qt5::Core Qt5::Gui)
endforeach()

EXPORT(TARGETS codegen_emoji codegen_lang codegen_numbers codegen_style FILE ${CMAKE_BINARY_DIR}/ImportExecutables.cmake )
