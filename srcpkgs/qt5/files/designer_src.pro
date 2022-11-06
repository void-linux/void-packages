TEMPLATE = subdirs

SUBDIRS = \
    uiplugin \
    uitools

SUBDIRS += \
    lib \
    components \
    designer

lib.depends = uiplugin
components.depends = lib
designer.depends = components
plugins.depends = lib

SUBDIRS += plugins

uitools.depends = uiplugin
