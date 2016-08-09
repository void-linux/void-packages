QT = core-private dbus-private
QMAKE_CXXFLAGS += $$QT_HOST_CFLAGS_DBUS

SOURCES = qdbusxml2cpp.cpp

load(qt_tool)
