QT = core qml qmldevtools-private

SOURCES += main.cpp \
    componentversion.cpp \
    findunqualified.cpp \
    importedmembersvisitor.cpp \
    qcoloroutput.cpp \
    scopetree.cpp \
    typedescriptionreader.cpp \
    ../../src/qml/qqmljsgrammar.cpp

QMAKE_TARGET_DESCRIPTION = QML Syntax Verifier

load(qt_tool)

HEADERS += \
    componentversion.h \
    findunqualified.h \
    importedmembersvisitor.h \
    metatypes.h \
    qcoloroutput.h \
    scopetree.h \
    typedescriptionreader.h
