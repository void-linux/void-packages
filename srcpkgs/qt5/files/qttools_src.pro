TEMPLATE = subdirs

QT_FOR_CONFIG += widgets
SUBDIRS = assistant \
	pixeltool \
	designer \
	linguist \
	qdbus \
	qtattributionsscanner

linguist.depends = designer
qtHaveModule(quick):qtConfig(thread):qtConfig(toolbutton): SUBDIRS += distancefieldgenerator


qtConfig(library) {
    !android|android_app: SUBDIRS += qtplugininfo
}

!android|android_app: SUBDIRS += qtpaths

macos {
    SUBDIRS += macdeployqt
}

win32|winrt:SUBDIRS += windeployqt
winrt:SUBDIRS += winrtrunner
qtHaveModule(gui):!wasm:!android:!uikit:!qnx:!winrt: SUBDIRS += qtdiag

qtNomakeTools( \
    distancefieldgenerator \
    pixeltool \
)

# This is necessary to avoid a race condition between toolchain.prf
# invocations in a module-by-module cross-build.
cross_compile:isEmpty(QMAKE_HOST_CXX.INCDIRS) {
    windeployqt.depends += qtattributionsscanner
    winrtrunner.depends += qtattributionsscanner
    linguist.depends += qtattributionsscanner
}
