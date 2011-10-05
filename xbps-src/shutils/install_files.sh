#-
# Copyright (c) 2011 Juan Romero Pardines.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#-

vinstall()
{
	local file="$1"
	local mode="$2"
	local targetdir="$3"
	local targetfile="$4"

	if [ -z "$DESTDIR" ]; then
		msg_red "vinstall: DESTDIR unset, can't continue...\n"
		return 1
	fi

	if [ $# -lt 3 ]; then
		msg_red "vinstall: 3 arguments expected: <file> <mode> <target-directory>\n"
		return 1
	fi

	if [ ! -r "$file" ]; then
		msg_red "vinstall: cannot find '$file'...\n"
		return 1
	fi

	if [ -z "$targetfile" ]; then
		install -Dm${mode} ${file} "${DESTDIR}/${targetdir}/$(basename ${file})"
	else
		install -Dm${mode} ${file} "${DESTDIR}/${targetdir}/$(basename ${targetfile})"
	fi
}

vcopy()
{
	local files=$1
	local targetdir="$2"

	if [ -z "$DESTDIR" ]; then
		msg_red "vcopy: DESTDIR unset, can't continue...\n"
		return 1
	fi
	if [ $# -ne 2 ]; then
		msg_red "vcopy: 2 arguments expected: <files> <target-directory>\n"
		return 1
	fi

	cp -a $files ${DESTDIR}/${targetdir}
}

vmove()
{
	local files=$1
	local targetdir="$2"

	if [ -z "$DESTDIR" ]; then
		msg_red "vmove: DESTDIR unset, can't continue...\n"
		return 1
	elif [ -z "$SRCPKGDESTDIR" ]; then
		msg_red "vmove: SRCPKGDESTDIR unset, can't continue...\n"
		return 1
	fi
	if [ $# -lt 1 ]; then
		msg_red "vmove: 1 argument expected: <files>\n"
		return 1
	fi
	if [ -z "${targetdir}" ]; then
		[ ! -d ${DESTDIR} ] && install -d ${DESTDIR}
		mv ${SRCPKGDESTDIR}/$files ${DESTDIR}
	else
		[ ! -d ${DESTDIR}/${targetdir} ] && vmkdir ${targetdir}
		mv ${SRCPKGDESTDIR}/$files ${DESTDIR}/${targetdir}
	fi
}

vmkdir()
{
	local dir="$1"
	local mode="$2"

	if [ -z "$DESTDIR" ]; then
		msg_red "vmkdir: DESTDIR unset, can't continue...\n"
		return 1
	fi

	if [ -z "$dir" ]; then
		msg_red "vmkdir: directory argument unset.\n"
		return 1
	fi

	if [ -z "$mode" ]; then
		install -d ${DESTDIR}/${dir}
	else
		install -dm${mode} ${DESTDIR}/${dir}
	fi
}
