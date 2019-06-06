project(qtlottie)

set(CMAKE_CXX_STANDARD 17)

set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

list(APPEND CMAKE_MODULE_PATH
	${CMAKE_SOURCE_DIR}/gyp
)

find_package(Qt5 REQUIRED COMPONENTS Core Gui)

foreach(__qt_module IN ITEMS QtCore QtGui)
	list(APPEND QT_PRIVATE_INCLUDE_DIRS
		${QT_INCLUDE_DIR}/${__qt_module}/${Qt5_VERSION}
		${QT_INCLUDE_DIR}/${__qt_module}/${Qt5_VERSION}/${__qt_module}
	)
endforeach()

file(GLOB QTLOTTIE_SOURCE_FILES
	src/bodymovin/*.cpp
	src/imports/rasterrenderer/rasterrenderer.cpp
	../../SourceFiles/lottie/*.cpp
)

add_library(${PROJECT_NAME} STATIC ${QTLOTTIE_SOURCE_FILES})

include(PrecompiledHeader)
add_precompiled_header(${PROJECT_NAME} ../../SourceFiles/lottie/lottie_pch.h)

target_include_directories(${PROJECT_NAME} PUBLIC
	src
	src/bodymovin
	src/imports
	${CMAKE_SOURCE_DIR}/SourceFiles
	${CMAKE_SOURCE_DIR}/ThirdParty/GSL/include
	${CMAKE_SOURCE_DIR}/ThirdParty/variant/include
	${QT_PRIVATE_INCLUDE_DIRS}
)
set_target_properties(${PROJECT_NAME} PROPERTIES AUTOMOC_MOC_OPTIONS -bqtlottie_pch/lottie_pch.h)
target_compile_definitions(${PROJECT_NAME} PUBLIC BODYMOVIN_LIBRARY)
target_link_libraries(${PROJECT_NAME} crl Qt5::Core Qt5::Widgets)
