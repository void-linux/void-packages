TEMPLATE = subdirs

SUBDIRS = assistant \
	pixeltool \
	designer \
	linguist \
	qdbus \
	qdoc \
	qtattributionsscanner

linguist.depends = designer

qtConfig(library) {
    !android|android_app: SUBDIRS += qtplugininfo
}

if(!android|android_app):!uikit: SUBDIRS += qtpaths

mac {
    SUBDIRS += macdeployqt
}

android {
    SUBDIRS += androiddeployqt
}

win32|winrt:SUBDIRS += windeployqt
winrt:SUBDIRS += winrtrunner
qtHaveModule(gui):!android:!uikit:!qnx:!winrt: SUBDIRS += qtdiag

qtNomakeTools( \
    macdeployqt \
)

# This is necessary to avoid a race condition between toolchain.prf
# invocations in a module-by-module cross-build.
cross_compile:isEmpty(QMAKE_HOST_CXX.INCDIRS) {
    androiddeployqt.depends += qtattributionsscanner
    qdoc.depends += qtattributionsscanner
    windeployqt.depends += qtattributionsscanner
    winrtrunner.depends += qtattributionsscanner
    linguist.depends += qtattributionsscanner
}
