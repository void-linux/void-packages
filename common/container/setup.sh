#!/bin/sh

: "${MIRROR:=https://repo-default.voidlinux.org/}"

suffix() {
	case "${LIBC:?}" in
	musl) echo "-musl" ;;
	esac
}

repo() {
	case "${ARCH:?}" in
	aarch64*) echo "${MIRROR}/current/aarch64" ;;
	*-musl)   echo "${MIRROR}/current/musl"    ;;
	*)        echo "${MIRROR}/current"         ;;
	esac
}

case "${TARGETPLATFORM:?}" in
linux/arm/v6) ARCH="armv6l$(suffix)"  ;;
linux/arm/v7) ARCH="armv7l$(suffix)"  ;;
linux/arm64)  ARCH="aarch64$(suffix)" ;;
linux/amd64)  ARCH="x86_64$(suffix)"  ;;
linux/386)    ARCH="i686$(suffix)"    ;;
esac

REPO="$(repo)"

export ARCH REPO
