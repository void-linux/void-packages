QT = core qml qmldevtools-private

SOURCES += main.cpp \
    componentversion.cpp \
    fakemetaobject.cpp \
    findunqualified.cpp \
    qmljstypedescriptionreader.cpp \
    qcoloroutput.cpp \
    scopetree.cpp \
    ../../src/qml/qqmljsgrammar.cpp

QMAKE_TARGET_DESCRIPTION = QML Syntax Verifier

load(qt_tool)

HEADERS += \
    componentversion.h \
    fakemetaobject.h \
    findunqualified.h \
    qmljstypedescriptionreader.h \
    qcoloroutput_p.h \
    scopetree.h
