QT = core-private dbus-private
DEFINES += QT_NO_CAST_FROM_ASCII QT_NO_FOREACH
QMAKE_CXXFLAGS += $$QT_HOST_CFLAGS_DBUS

SOURCES = qdbusxml2cpp.cpp

QMAKE_TARGET_DESCRIPTION = "Qt D-Bus XML to C++ Compiler"
load(qt_tool)
