QT = core qml core-private qmldevtools-private
DEFINES += QT_UIC QT_NO_CAST_FROM_ASCII QT_NO_FOREACH

include(uic.pri)
include(shared/shared.pri)
include(cpp/cpp.pri)
include(python/python.pri)

HEADERS += uic.h

SOURCES += main.cpp \
           uic.cpp

QMAKE_TARGET_DESCRIPTION = "Qt User Interface Compiler"
load(qt_tool)
