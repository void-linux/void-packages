QT = core qml qmldevtools-private
DEFINES += QT_NO_CAST_TO_ASCII QT_NO_CAST_FROM_ASCII

SOURCES = qmlcachegen.cpp \
    resourcefilter.cpp \
    generateloader.cpp
TARGET = qmlcachegen

include(../shared/shared.pri)

build_integration.files = qmlcache.prf qtquickcompiler.prf
build_integration.path = $$[QT_HOST_DATA]/mkspecs/features
prefix_build: INSTALLS += build_integration
else: COPIES += build_integration

load(cmake_functions)

CMAKE_BIN_DIR = $$cmakeRelativePath($$[QT_HOST_BINS], $$[QT_INSTALL_PREFIX])
contains(CMAKE_BIN_DIR, "^\\.\\./.*") {
    CMAKE_BIN_DIR = $$[QT_HOST_BINS]/
    CMAKE_BIN_DIR_IS_ABSOLUTE = True
}

load(qt_build_paths)

equals(QMAKE_HOST.os, Windows): CMAKE_BIN_SUFFIX = ".exe"
cmake_config_file.input = $$PWD/Qt5QuickCompilerConfig.cmake.in
cmake_config_file.output = $$MODULE_BASE_OUTDIR/lib/cmake/Qt5QuickCompiler/Qt5QuickCompilerConfig.cmake
QMAKE_SUBSTITUTES += cmake_config_file

cmake_build_integration.files = $$cmake_config_file.output
cmake_build_integration.path = $$[QT_INSTALL_LIBS]/cmake/Qt5QuickCompiler
prefix_build: INSTALLS += cmake_build_integration
else: COPIES += cmake_build_integration

QMAKE_TARGET_DESCRIPTION = QML Cache Generator

load(qt_tool)
