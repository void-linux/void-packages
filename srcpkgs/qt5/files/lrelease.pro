QT = core qml network core-private
DEFINES += QT_NO_CAST_FROM_ASCII QT_NO_CAST_TO_ASCII

HEADERS += \
    ../shared/projectdescriptionreader.h \
    ../shared/runqttool.h

SOURCES += \
    ../shared/projectdescriptionreader.cpp \
    ../shared/runqttool.cpp \
    main.cpp

include(../shared/formats.pri)

qmake.name = QMAKE
qmake.value = $$shell_path($$QMAKE_QMAKE)
QT_TOOL_ENV += qmake

QMAKE_TARGET_DESCRIPTION = "Qt Translation File Compiler"
load(qt_tool)
