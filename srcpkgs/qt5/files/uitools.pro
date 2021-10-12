TARGET = QtUiTools
CONFIG += static

include(../lib/uilib/uilib.pri)

QMAKE_DOCS = $$PWD/doc/qtuitools.qdocconf

HEADERS += quiloader.h
SOURCES += quiloader.cpp

DEFINES += \
    QFORMINTERNAL_NAMESPACE \
    QT_DESIGNER_STATIC

load(qt_module)
