QT = core qml qmldevtools-private

SOURCES += main.cpp \
    commentastvisitor.cpp \
    dumpastvisitor.cpp \
    restructureastvisitor.cpp \
    ../../src/qml/qqmljsgrammar.cpp

QMAKE_TARGET_DESCRIPTION = QML Formatter

HEADERS += \
    commentastvisitor.h \
    dumpastvisitor.h \
    restructureastvisitor.h

load(qt_tool)
