QT = core-private dbus-private
QMAKE_CXXFLAGS += $$QT_HOST_CFLAGS_DBUS

include(../moc/moc.pri)

SOURCES += qdbuscpp2xml.cpp

load(qt_tool)
