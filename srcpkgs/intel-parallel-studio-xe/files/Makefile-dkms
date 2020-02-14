#
# Version: 1.6
#
# Copyright (C) 2008-2019 Intel Corporation.  All Rights Reserved.
#
#     This file is part of SEP Development Kit
#
#     SEP Development Kit is free software; you can redistribute it
#     and/or modify it under the terms of the GNU General Public License
#     version 2 as published by the Free Software Foundation.
#
#     SEP Development Kit is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with SEP Development Kit; if not, write to the Free Software
#     Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#     As a special exception, you may use this file as part of a free software
#     library without restriction.  Specifically, if other files instantiate
#     templates or use macros or inline functions from this file, or you compile
#     this file and link it with other files to produce an executable, this
#     file does not by itself cause the resulting executable to be covered by
#     the GNU General Public License.  This exception does not however
#     invalidate any other reasons why the executable file might be covered by
#     the GNU General Public License.
#

# -------------------- user configurable options ------------------------

# base name of SEP driver
DRIVER_NAME = sep5

# location to install driver
ifeq ($(INSTALL),)
INSTALL = .
endif

# current working directory
DRV_CWD := $(shell pwd)/src

# If KERNELRELEASE is defined, we've been invoked from the
# kernel build system and can use its language.
# Example flags are "-Werror", "-Wno-error", etc.
EXTRA_CFLAGS += -I$(LDDINCDIR) -I$(LDDINCDIR1)

# if ARCH variable is set, unset it to avoid conflicts with kbuild
unexport ARCH

# platform details
MACH ?= $(shell uname -m)
export MACH
ifeq ($(MACH),x86_64)
PLATFORM=x32_64
endif
ifeq ($(PLATFORM),)
PLATFORM=x32
endif
KERNEL_VERSION ?= $(shell uname -r)
SMP ?= $(shell uname -v | grep SMP)
ARITY=up
ifneq ($(SMP),)
ARITY=smp
endif

ifeq ($(PER_USER_MODE),YES)
SEP_PER_USER=-pu
endif


# this is a temporary work-around for handling the module structure changes across multiple kernels.
# need to find out a proper solution.
ifneq ($(KERNEL_SRC_DIR),)
    PATH_PREFIX = $(KERNEL_SRC_DIR)
endif
PATH_PREFIX ?= /lib/modules/$(shell uname -r)/build
ifneq ($(shell grep -s $(PATH_PREFIX)/include/linux/module.h -we "struct module_layout"),)
    EXTRA_CFLAGS += -DSEP_CONFIG_MODULE_LAYOUT
endif

ifeq ($(shell test -e $(PATH_PREFIX)/include/linux/kaiser.h && echo -n YES),YES)
    EXTRA_CFLAGS += -DKAISER_HEADER_PRESENT
endif

# eventual filename of SEP driver
DRIVER_MODE=$(DRIVER_NAME)$(SEP_PER_USER)
DRIVER_TYPE=$(PLATFORM)-$(KERNEL_VERSION)$(ARITY)
DRIVER_FILENAME=$(DRIVER_MODE)-$(DRIVER_TYPE).ko

	KERNEL_SRC_DIR ?= /lib/modules/$(shell uname -r)/build
	PWD := $(shell pwd)

socperfdir=$(DRV_CWD)/socperf
ifeq ($(wildcard $(socperfdir)),)
    socperfdir=
endif

all: default

modules: default

default:
	@(cd $(socperfdir)/src && make all)
	@cp $(socperfdir)/src/Module*.symvers src/.
	$(MAKE) -C $(KERNEL_SRC_DIR) M=$(PWD)/src LDDINCDIR=$(PWD)/src/../include LDDINCDIR1=$(PWD)/src/inc modules PWD=$(PWD)/src KBUILD_EXTRA_SYMBOLS=$(socperfdir)/src/Module.symvers
	cp src/$(DRIVER_NAME).ko src/$(DRIVER_FILENAME)
	@(cd src/pax && make all)
	@if [ -d src/vtsspp ]; then          \
		(cd src/vtsspp && make all); \
	fi;

clean:
	( cd src && rm -f *.o .*.o.cmd .*.o.d .*.ko.cmd .*.ko.unsigned.cmd *.gcno .cache.mk *.o.ur-safe .*.o.tmp; \
	rm -f $(DRIVER_NAME).ko $(DRIVER_NAME).ko.unsigned; \
	rm -f $(DRIVER_MODE)*$(DRIVER_TYPE).ko; \
	rm -f Module.symvers Modules.symvers *.mod.c modules.order Module.markers; \
	rm -rf .tmp_versions )
	@(cd src/pax && make clean)
	@(cd $(socperfdir)/src && make clean)
	@if [ -d src/vtsspp ]; then            \
		(cd src/vtsspp && make clean); \
	fi;

distclean: clean
	( cd src && rm -f $(DRIVER_NAME)*.ko )
	@(cd src/pax && make distclean)
	@(cd $(socperfdir)/src && make distclean)
	@if [ -d src/vtsspp ]; then                \
		(cd src/vtsspp && make distclean); \
	fi;
