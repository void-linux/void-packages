QT = core-private dbus-private
DEFINES += QT_NO_CAST_FROM_ASCII QT_NO_FOREACH
QMAKE_CXXFLAGS += $$QT_HOST_CFLAGS_DBUS

include(../moc/moc.pri)

SOURCES += qdbuscpp2xml.cpp

QMAKE_TARGET_DESCRIPTION = "Qt D-Bus C++ to XML Compiler"
load(qt_tool)
