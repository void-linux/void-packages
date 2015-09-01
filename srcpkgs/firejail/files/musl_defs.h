#ifndef _MUSL_DEFS_H
#define _MUSL_DEFS_H

#include <features.h>

#define __NEED_FILE
#define __NEED_dev_t
#define __NEED_ino_t
#define __NEED_mode_t
#define __NEED_nlink_t
#define __NEED_uid_t
#define __NEED_gid_t
#define __NEED_off_t
#define __NEED_time_t
#define __NEED_blksize_t
#define __NEED_blkcnt_t
#define __NEED_struct_timespec

#include <bits/alltypes.h>
#include <bits/stat.h>

#ifdef __cplusplus
#define NULL 0L
#else
#define NULL ((void*)0)
#endif

int printf(const char *format, ...);
int sprintf(char *buffer, const char *format, ...);
char *fgets(char *buffer, int size, FILE *fp);

#endif

