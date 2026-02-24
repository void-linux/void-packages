TEMPLATE = subdirs

SUBDIRS += \
           help \
           assistant \
           qhelpgenerator \
           qcollectiongenerator \

assistant.depends = help
qcollectiongenerator.depends = help
qhelpconverter.depends = help
