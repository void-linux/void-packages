QT = core qml qmldevtools-private

SOURCES += main.cpp ../../src/qml/qqmljsgrammar.cpp

QMAKE_TARGET_DESCRIPTION = QML Syntax Verifier

load(qt_tool)
