QT = core qml network qmldevtools-private
DEFINES += QT_NO_CAST_TO_ASCII QT_NO_CAST_FROM_ASCII

SOURCES += main.cpp ../../src/qml/qqmljsgrammar.cpp

include(../shared/shared.pri)

QMAKE_TARGET_DESCRIPTION = QML Import Scanner

load(qt_tool)
