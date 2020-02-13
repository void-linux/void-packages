QT = core qml network core-private qmldevtools-private

DEFINES += QT_NO_CAST_TO_ASCII QT_NO_CAST_FROM_ASCII

include(../shared/formats.pri)


SOURCES += \
    main.cpp \
    merge.cpp \
    ../shared/projectdescriptionreader.cpp \
    ../shared/runqttool.cpp \
    ../shared/qrcreader.cpp \
    ../shared/simtexth.cpp \
    \
    cpp.cpp \
    java.cpp \
    ui.cpp

SOURCES += qdeclarative.cpp

HEADERS += \
    lupdate.h \
    ../shared/projectdescriptionreader.h \
    ../shared/qrcreader.h \
    ../shared/runqttool.h \
    ../shared/simtexth.h

mingw {
    RC_FILE = lupdate.rc
}

qmake.name = QMAKE
qmake.value = $$shell_path($$QMAKE_QMAKE)
QT_TOOL_ENV += qmake

QMAKE_TARGET_DESCRIPTION = "Qt Translation File Update Tool"
load(qt_tool)
