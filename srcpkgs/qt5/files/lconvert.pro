QT = core-private
DEFINES += QT_NO_CAST_FROM_ASCII QT_NO_CAST_TO_ASCII

SOURCES += main.cpp

include(../shared/formats.pri)

QMAKE_TARGET_DESCRIPTION = "Qt Translation File Converter"
load(qt_tool)
