QT = core qml network qmldevtools-private

SOURCES += main.cpp ../../src/qml/parser/qqmljsgrammar.cpp

QMAKE_TARGET_DESCRIPTION = QML Syntax Verifier

load(qt_tool)
