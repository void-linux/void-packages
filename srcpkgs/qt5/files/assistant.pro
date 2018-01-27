TEMPLATE = subdirs

SUBDIRS += \
           help \
           assistant \
           qhelpgenerator \
           qcollectiongenerator \
           qhelpconverter

assistant.depends = help
qhelpgenerator.depends = help
qcollectiongenerator.depends = help
qhelpconverter.depends = help
