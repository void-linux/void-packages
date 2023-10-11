# Based on 'Makefile.Debian', part of pdftk
# Copyright (c) 2004-2012 Sid Steward

export CXX= @CXX@
export GCJ= gcj-6
export GCJH= gcjh-6
export GJAR= gjar-6
export LIBGCJ= /usr/share/java/libgcj.jar
export AR= @AR@
export RM= rm
export ARFLAGS= rs
export RMFLAGS= -vf
export CPPFLAGS= -DPATH_DELIM=0x2f -DASK_ABOUT_WARNINGS=false -DUNBLOCK_SIGNALS -fdollars-in-identifiers
export CXXFLAGS= @CXXFLAGS@
export GCJFLAGS= -Wno-all -fsource=1.3 -O2 -fPIC -L/usr/lib
export GCJHFLAGS= -force
export LDLIBS= @LDFLAGS@ -lgcj

include Makefile.Base
