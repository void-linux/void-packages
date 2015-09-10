/*
 * Copyright 1996-2004 by Hans Reiser, licensing governed by
 * reiserfsprogs/README
 */

#define _GNU_SOURCE

#include "includes.h"
#include <stdarg.h>
#include <stdint.h>
#include <limits.h>
#if defined(__GLIBC__)
#include <printf.h>
#endif
#include <limits.h>
#include <time.h>

#if defined(HAVE_LIBUUID) && defined(HAVE_UUID_UUID_H)
#  include <uuid/uuid.h>
#endif


char ftypelet (mode_t mode)
{
    if (S_ISBLK (mode))
	return 'b';
    if (S_ISCHR (mode))
	return 'c';
    if (S_ISDIR (mode))
	return 'd';
    if (S_ISREG (mode))
	return '-';
    if (S_ISFIFO (mode))
	return 'p';
    if (S_ISLNK (mode))
	return 'l';
    if (S_ISSOCK (mode))
	return 's';
    return '?';
}


static int rwx (FILE * stream, mode_t mode)
{
    return fprintf (stream, "%c%c%c",
		    (mode & S_IRUSR) ? 'r' : '-',
		    (mode & S_IWUSR) ? 'w' : '-',
		    (mode & S_IXUSR) ? 'x' : '-');
}

#if defined(__GLIBC__)

#ifndef HAVE_REGISTER_PRINTF_SPECIFIER
#define register_printf_specifier(x, y, z) register_printf_function(x, y, z)
static int arginfo_ptr (const struct printf_info *info, size_t n,
			int *argtypes)
#else
static int arginfo_ptr (const struct printf_info *info, size_t n,
			int *argtypes, int *size)
#endif
{
	if (n > 0) {
		argtypes[0] = PA_FLAG_PTR;
#ifdef HAVE_REGISTER_PRINTF_SPECIFIER
		size[0] = sizeof (void *);
#endif
	}
	return 1;
}

#define FPRINTF \
    if (len == -1) {\
	return -1;\
    }\
    len = fprintf (stream, "%*s",\
		   info->left ? -info->width : info->width, buffer);\
    free (buffer);\
    return len;\


/* %b */
static int print_block_head (FILE * stream,
			     const struct printf_info *info,
			     const void *const *args)
{
    const struct buffer_head * bh;
    char * buffer;
    int len;

    bh = *((const struct buffer_head **)(args[0]));
    len = asprintf (&buffer, "level=%d, nr_items=%d, free_space=%d rdkey",
		    B_LEVEL (bh), B_NR_ITEMS (bh), B_FREE_SPACE (bh));
    FPRINTF;
}


/* %K */
static int print_short_key (FILE * stream,
			    const struct printf_info *info,
			    const void *const *args)
{
    const struct key * key;
    char * buffer;
    int len;

    key = *((const struct key **)(args[0]));
    len = asprintf (&buffer, "[%u %u]", get_key_dirid (key),
		    get_key_objectid (key));
    FPRINTF;
}


/* %k */
static int print_key (FILE * stream,
		      const struct printf_info *info,
		      const void *const *args)
{
    const struct key * key;
    char * buffer;
    int len;

    key = *((const struct key **)(args[0]));
    len = asprintf (&buffer, "[%u %u 0x%Lx %s (%d)]",
		    get_key_dirid (key), get_key_objectid (key),
		    (unsigned long long)get_offset (key), key_of_what (key), get_type (key));
    FPRINTF;
}


/* %H */
static int print_item_head (FILE * stream,
			    const struct printf_info *info,
			    const void *const *args)
{
    const struct item_head * ih;
    char * buffer;
    int len;

    ih = *((const struct item_head **)(args[0]));
    len = asprintf (&buffer, "%u %u 0x%Lx %s (%d), "
		    "len %u, location %u entry count %u, fsck need %u, format %s",
		    get_key_dirid (&ih->ih_key), get_key_objectid (&ih->ih_key),
		    (unsigned long long)get_offset (&ih->ih_key), key_of_what (&ih->ih_key),
		    get_type (&ih->ih_key), get_ih_item_len (ih), get_ih_location (ih),
		    get_ih_entry_count (ih), get_ih_flags (ih),
		    get_ih_key_format (ih) == KEY_FORMAT_2 ? "new" :
		    ((get_ih_key_format (ih) == KEY_FORMAT_1) ? "old" : "BAD"));
    FPRINTF;
}


static int print_disk_child (FILE * stream,
			     const struct printf_info *info,
			     const void *const *args)
{
    const struct disk_child * dc;
    char * buffer;
    int len;

    dc = *((const struct disk_child **)(args[0]));
    len = asprintf (&buffer, "[dc_number=%u, dc_size=%u]", get_dc_child_blocknr (dc),
		    get_dc_child_size (dc));
    FPRINTF;
}


/* %M */
static int print_sd_mode (FILE * stream,
			  const struct printf_info *info,
			  const void *const *args)
{
    int len = 0;
    __u16 mode;

    mode = *(mode_t *)args[0];
    len = fprintf (stream, "%c", ftypelet (mode));
    len += rwx (stream, (mode & 0700) << 0);
    len += rwx (stream, (mode & 0070) << 3);
    len += rwx (stream, (mode & 0007) << 6);
    return len;
}

/* %U */
static int print_sd_uuid (FILE * stream,
			  const struct printf_info *info,
			  const void *const *args)
{
#if defined(HAVE_LIBUUID) && defined(HAVE_UUID_UUID_H)
    const unsigned char *uuid = *((const unsigned char **)(args[0]));
    char buf[37];

    buf[36] = '\0';
    uuid_unparse(uuid, buf);
    return fprintf(stream, "%s", buf);
#else
    return fprintf(stream, "<no libuuid installed>");
#endif
}

void reiserfs_warning (FILE * fp, const char * fmt, ...)
{
    static int registered = 0;
    va_list args;

    if (!registered) {
	registered = 1;

	register_printf_specifier ('K', print_short_key, arginfo_ptr);
	register_printf_specifier ('k', print_key, arginfo_ptr);
	register_printf_specifier ('H', print_item_head, arginfo_ptr);
	register_printf_specifier ('b', print_block_head, arginfo_ptr);
	register_printf_specifier ('y', print_disk_child, arginfo_ptr);
	register_printf_specifier ('M', print_sd_mode, arginfo_ptr);
	register_printf_specifier ('U', print_sd_uuid, arginfo_ptr);
    }

    va_start (args, fmt);
    vfprintf (fp, fmt, args);
    va_end (args);
}

#else	/* defined(__GLIBC__) */

typedef void* void_ptr;

void reiserfs_warning (FILE * fp, const char * fmt, ...)
{
	char * buffer;
	int len;
	char format_buf[32];
	char* dst = format_buf;
	char* end = &dst[30];
	const struct buffer_head * bh;
	const struct item_head * ih;
	const struct disk_child * dc;
	const struct key * key;
	uint16_t mode;
#if defined(HAVE_LIBUUID) && defined(HAVE_UUID_UUID_H)
	const unsigned char *uuid;
	char uuid_buf[37];
#endif
	va_list args;
	int esc = 0;

	va_start (args, fmt);
	while (*fmt) {
		int ch = *fmt++;
		if (esc) {
			switch (ch) {
			case '%':
				fputc(ch, fp);
				esc = 0;
				break;
			case 'b':	// block head
				bh = (const struct buffer_head *) va_arg(args, void_ptr);
				len = asprintf(&buffer, "level=%d, nr_items=%d, free_space=%d rdkey",
					B_LEVEL (bh), B_NR_ITEMS (bh), B_FREE_SPACE (bh));
				*dst++ = 's';
				*dst = '\0';
				fprintf(fp, format_buf, buffer);
				esc = 0;
				break;
			case 'K':	// short key
				key = (const struct key *) va_arg(args, void_ptr);
				len = asprintf(&buffer, "[%u %u]", get_key_dirid (key),
					get_key_objectid (key));
				*dst++ = 's';
				*dst = '\0';
				fprintf(fp, format_buf, buffer);
				esc = 0;
				break;
			case 'k':	// key
				key = (const struct key *) va_arg(args, void_ptr);
				len = asprintf(&buffer, "[%u %u 0x%Lx %s (%d)]",
					get_key_dirid (key), get_key_objectid (key),
					(unsigned long long)get_offset (key), key_of_what (key), get_type (key));
				*dst++ = 's';
				*dst = '\0';
				fprintf(fp, format_buf, buffer);
				esc = 0;
				break;
			case 'H':	// item head
				ih = (const struct item_head *) va_arg(args, void_ptr);
				len = asprintf(&buffer, "%u %u 0x%Lx %s (%d), "
					    "len %u, location %u entry count %u, fsck need %u, format %s",
					get_key_dirid (&ih->ih_key), get_key_objectid (&ih->ih_key),
					(unsigned long long)get_offset (&ih->ih_key), key_of_what (&ih->ih_key),
					get_type (&ih->ih_key), get_ih_item_len (ih), get_ih_location (ih),
					get_ih_entry_count (ih), get_ih_flags (ih),
					get_ih_key_format (ih) == KEY_FORMAT_2 ?
						"new" :
						((get_ih_key_format (ih) == KEY_FORMAT_1) ? "old" : "BAD"));
				*dst++ = 's';
				*dst = '\0';
				fprintf(fp, format_buf, buffer);
				esc = 0;
				break;
			case 'y':	// disk child
				dc = (const struct disk_child *) va_arg(args, void_ptr);
				len = asprintf(&buffer, "[dc_number=%u, dc_size=%u]", get_dc_child_blocknr (dc),
						get_dc_child_size (dc));
				*dst++ = 's';
				*dst = '\0';
				fprintf(fp, format_buf, buffer);
				esc = 0;
				break;
			case 'M':	// sd mode
				mode = (mode_t) va_arg(args, void_ptr);
				fputc(ftypelet (mode), fp);
				rwx (fp, (mode & 0700) << 0);
				rwx (fp, (mode & 0070) << 3);
				rwx (fp, (mode & 0007) << 6);
				esc = 0;
				break;
			case 'U':	// UUID
#if defined(HAVE_LIBUUID) && defined(HAVE_UUID_UUID_H)
				uuid = (const unsigned char *) va_arg(args, void_ptr);
				uuid_buf[36] = '\0';
				uuid_unparse(uuid, uuid_buf);
				fprintf(fp, "%s", uuid_buf);
#else
				fprintf(fp, "<no libuuid installed>");
#endif
				esc = 0;
				break;
			case '-': case '+': case '#': case '.':
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6': case '7': case '8': case '9':
			case 'l': case 'L': case 'h':
				// non-terminal format modifiers
				if (dst < end)
					*dst++ = ch;
				break;
			default:
				*dst++ = ch;
				*dst = '\0';
				fprintf(fp, format_buf, va_arg(args, void_ptr));
				esc = 0;
				break;
			}
		} else if (ch == '%') {
			esc = 1;
			dst = format_buf;
			end = &dst[30];	// leave room for final "s\0"
			*dst++ = ch;
		} else {
			fputc(ch, fp);
		}
	}

	va_end (args);
}

#endif	/* !defined(__GLIBC__) */


static char * vi_type (struct virtual_item * vi)
{
    static char *types[]={"directory", "direct", "indirect", "stat data"};

    if (vi->vi_type & VI_TYPE_STAT_DATA)
	return types[3];
    if (vi->vi_type & VI_TYPE_INDIRECT)
	return types[2];
    if (vi->vi_type & VI_TYPE_DIRECT)
	return types[1];
    if (vi->vi_type & VI_TYPE_DIRECTORY)
	return types[0];

    reiserfs_panic ("vi_type: 6000: unknown type (0x%x)", vi->vi_type);
    return NULL;
}


void print_virtual_node (struct virtual_node * vn)
{
    int i, j;

    printf ("VIRTUAL NODE CONTAINS %d items, has size %d,%s,%s, ITEM_POS=%d POS_IN_ITEM=%d MODE=\'%c\'\n",
	    vn->vn_nr_item, vn->vn_size,
	    (vn->vn_vi[0].vi_type & VI_TYPE_LEFT_MERGEABLE )? "left mergeable" : "",
	    (vn->vn_vi[vn->vn_nr_item - 1].vi_type & VI_TYPE_RIGHT_MERGEABLE) ? "right mergeable" : "",
	    vn->vn_affected_item_num, vn->vn_pos_in_item, vn->vn_mode);


    for (i = 0; i < vn->vn_nr_item; i ++) {
	printf ("%s %d %d", vi_type (&vn->vn_vi[i]), i, vn->vn_vi[i].vi_item_len);
	if (vn->vn_vi[i].vi_entry_sizes)
	{
	    printf ("It is directory with %d entries: ", vn->vn_vi[i].vi_entry_count);
	    for (j = 0; j < vn->vn_vi[i].vi_entry_count; j ++)
		printf ("%d ", vn->vn_vi[i].vi_entry_sizes[j]);
	}
	printf ("\n");
    }
}


void print_path (struct tree_balance * tb, struct path * path)
{
    int offset = path->path_length;
    struct buffer_head * bh;

    printf ("Offset    Bh     (b_blocknr, b_count) Position Nr_item\n");
    while ( offset > ILLEGAL_PATH_ELEMENT_OFFSET ) {
	bh = PATH_OFFSET_PBUFFER (path, offset);
	printf ("%6d %10p (%9lu, %7d) %8d %7d\n", offset,
		bh, bh ? bh->b_blocknr : 0, bh ? bh->b_count : 0,
		PATH_OFFSET_POSITION (path, offset), bh ? B_NR_ITEMS (bh) : -1);

	offset --;
    }
}



void print_directory_item (FILE * fp, reiserfs_filsys_t * fs,
			   struct buffer_head * bh, struct item_head * ih)
{
    int i;
    int namelen;
    struct reiserfs_de_head * deh;
    char * name;
/*    static char namebuf [80];*/

    if (!I_IS_DIRECTORY_ITEM (ih))
	return;

    //printk ("\n%2%-25s%-30s%-15s%-15s%-15s\n", "    Name", "length", "Object key", "Hash", "Gen number", "Status");
    reiserfs_warning (fp, "%3s: %-25s%s%-22s%-12s%s\n", "###", "Name", "length", "    Object key", "   Hash", "Gen number");
    deh = B_I_DEH (bh, ih);
    for (i = 0; i < get_ih_entry_count (ih); i ++, deh ++) {
	if (dir_entry_bad_location (deh, ih, i == 0 ? 1 : 0)) {
	    reiserfs_warning (fp, "%3d: wrong entry location %u, deh_offset %u\n",
			      i, get_deh_location (deh), get_deh_offset (deh));
	    continue;
	}
	if (i && dir_entry_bad_location (deh - 1, ih, ((i - 1) == 0) ? 1 : 0))
	    /* previous entry has bad location so we can not calculate entry
	       length */
	    namelen = 25;
	else
	    namelen = name_in_entry_length (ih, deh, i);

	name = name_in_entry (deh, i);
	reiserfs_warning (fp, "%3d: \"%-25.*s\"(%3d)%20K%12d%5d, loc %u, state %x %s\n",
			  i, namelen, name, namelen,
			  (struct key *)&(deh->deh2_dir_id),
			  GET_HASH_VALUE (get_deh_offset (deh)),
			  GET_GENERATION_NUMBER (get_deh_offset (deh)),
			  get_deh_location (deh), get_deh_state (deh),
			  code2name (find_hash_in_use (name, namelen, get_deh_offset (deh),
						       fs ? get_sb_hash_code (fs->fs_ondisk_sb) : UNSET_HASH)));
	/*fs ? (is_properly_hashed (fs, name, namelen, deh_offset (deh)) ? "" : "(BROKEN)") : "??");*/
    }
}


//
// printing of indirect item
//
static void start_new_sequence (__u32 * start, int * len, __u32 new)
{
    *start = new;
    *len = 1;
}


static int sequence_finished (__u32 start, int * len, __u32 new)
{
    if (le32_to_cpu (start) == INT_MAX)
	return 1;

    if (start == 0 && new == 0) {
	(*len) ++;
	return 0;
    }
    if (start != 0 && (le32_to_cpu (start) + *len) == le32_to_cpu (new)) {
	(*len) ++;
	return 0;
    }
    return 1;
}

static void print_sequence (FILE * fp, __u32 start, int len)
{
    if (start == INT_MAX)
	return;

    if (len == 1)
	reiserfs_warning (fp, " %u", le32_to_cpu (start));
    else
	reiserfs_warning (fp, " %u(%d)", le32_to_cpu (start), len);
}


void print_indirect_item (FILE * fp, struct buffer_head * bh, int item_num)
{
    struct item_head * ih;
    unsigned int j;
    __u32 * unp, prev = INT_MAX;
    int num = 0;

    ih = B_N_PITEM_HEAD (bh, item_num);
    unp = (__u32 *)B_I_PITEM (bh, ih);

    if (get_ih_item_len (ih) % UNFM_P_SIZE)
	reiserfs_warning (fp, "print_indirect_item: invalid item len");

    reiserfs_warning (fp, "%d pointer%s\n[", I_UNFM_NUM (ih),
		      I_UNFM_NUM (ih) != 1 ? "s" : "" );
    for (j = 0; j < I_UNFM_NUM (ih); j ++) {
	if (sequence_finished (prev, &num, d32_get(unp, j))) {
	    print_sequence (fp, prev, num);
	    start_new_sequence (&prev, &num, d32_get(unp, j));
	}
    }
    print_sequence (fp, prev, num);
    reiserfs_warning (fp, "]\n");
}


char timebuf[256];

char * timestamp (time_t t)
{
    strftime (timebuf, 256, "%d/%Y %T", localtime (&t));
    return timebuf;
}

static int print_stat_data (FILE * fp, struct buffer_head * bh, struct item_head * ih, int alltimes)
{
    int retval;


    /* we cannot figure out if it is new stat data or old by key_format
       macro. Stat data's key looks identical in both formats */
    if (get_ih_key_format (ih) == KEY_FORMAT_1) {
	struct stat_data_v1 * sd_v1 = (struct stat_data_v1 *)B_I_PITEM (bh, ih);
	reiserfs_warning (fp, "(OLD SD), mode %M, size %u, nlink %u, uid %u, FDB %u, mtime %s blocks %u",
		sd_v1_mode(sd_v1), sd_v1_size(sd_v1), sd_v1_nlink(sd_v1),
		sd_v1_uid(sd_v1), sd_v1_first_direct_byte(sd_v1), timestamp
		(sd_v1_mtime(sd_v1)), sd_v1_blocks(sd_v1));
	retval = (S_ISLNK (sd_v1_mode(sd_v1))) ? 1 : 0;
	if (alltimes)
	    reiserfs_warning (fp, "%s %s\n", timestamp (sd_v1_ctime(sd_v1)),
		timestamp (sd_v1_atime(sd_v1)));
    } else {
	struct stat_data * sd = (struct stat_data *)B_I_PITEM (bh, ih);
	reiserfs_warning (fp, "(NEW SD), mode %M, size %Lu, nlink %u, mtime %s blocks %u, uid %u",
		sd_v2_mode(sd), sd_v2_size(sd), sd_v2_nlink(sd),
		timestamp (sd_v2_mtime(sd)), sd_v2_blocks(sd), sd_v2_uid(sd));
	retval = (S_ISLNK (sd_v2_mode(sd))) ? 1 : 0;
	if (alltimes)
	    reiserfs_warning (fp, "%s %s\n", timestamp (sd_v2_ctime(sd)),
		timestamp (sd_v2_atime(sd)));
    }

    reiserfs_warning (fp, "\n");
    return retval;
}


/* used by debugreiserfs/scan.c */
void reiserfs_print_item (FILE * fp, struct buffer_head * bh,
			  struct item_head * ih)
{
    reiserfs_warning (fp, "block %lu, item %d: %H\n",
	bh->b_blocknr, (ih - B_N_PITEM_HEAD (bh, 0))/sizeof(struct item_head), ih);
    if (is_stat_data_ih (ih)) {
	print_stat_data (fp, bh, ih, 0/*all times*/);
	return;
    }
    if (is_indirect_ih (ih)) {
	print_indirect_item (fp, bh, ih - B_N_PITEM_HEAD (bh, 0));
	return;
    }
    if (is_direct_ih (ih)) {
	reiserfs_warning (fp, "direct item: block %lu, start %d, %d bytes\n",
			  bh->b_blocknr, get_ih_location (ih), get_ih_item_len (ih));
	return;
    }

    print_directory_item (fp, 0, bh, ih);
}


/* this prints internal nodes (4 keys/items in line) (dc_number,
   dc_size)[k_dirid, k_objectid, k_offset, k_uniqueness](dc_number,
   dc_size)...*/
static int print_internal (FILE * fp, struct buffer_head * bh, int first, int last)
{
    struct key * key;
    struct disk_child * dc;
    int i;
    int from, to;

    if (!is_internal_node (bh))
	return 1;

    if (first == -1) {
	from = 0;
	to = B_NR_ITEMS (bh);
    } else {
	from = first;
	to = last < B_NR_ITEMS (bh) ? last : B_NR_ITEMS (bh);
    }

    reiserfs_warning (fp, "INTERNAL NODE (%lu) contains %b\n",  bh->b_blocknr, bh);

    dc = B_N_CHILD (bh, from);
    reiserfs_warning (fp, "PTR %d: %y ", from, dc);

    for (i = from, key = B_N_PDELIM_KEY (bh, from), dc ++; i < to; i ++, key ++, dc ++) {
	reiserfs_warning (fp, "KEY %d: %20k PTR %d: %20y ", i, key, i + 1, dc);
	if (i && i % 4 == 0)
	    reiserfs_warning (fp, "\n");
    }
    reiserfs_warning (fp, "\n");
    return 0;
}



static int is_symlink = 0;
static int print_leaf (FILE * fp, reiserfs_filsys_t * fs, struct buffer_head * bh,
		       int print_mode, int first, int last)
{
    struct item_head * ih;
    int i;
    int from, to;
    int real_nr, nr;

    if (!is_tree_node (bh, DISK_LEAF_NODE_LEVEL))
	return 1;

    ih = B_N_PITEM_HEAD (bh,0);
    real_nr = leaf_count_ih(bh->b_data, bh->b_size);
    nr = get_blkh_nr_items((struct block_head *)bh->b_data);

    reiserfs_warning (fp,
		      "\n===================================================================\n");
    reiserfs_warning (fp, "LEAF NODE (%lu) contains %b (real items %d)\n",
		      bh->b_blocknr, bh, real_nr);

    if (!(print_mode & PRINT_TREE_DETAILS)) {
	reiserfs_warning (fp, "FIRST ITEM_KEY: %k, LAST ITEM KEY: %k\n",
			   &(ih->ih_key), &((ih + real_nr - 1)->ih_key));
	return 0;
    }

    if (first < 0 || first > real_nr - 1)
	from = 0;
    else
	from = first;

    if (last < 0 || last > real_nr)
	to = real_nr;
    else
	to = last;


    reiserfs_warning (fp,
		       "-------------------------------------------------------------------------------\n"
		       "|###|type|ilen|f/sp| loc|fmt|fsck|                   key                      |\n"
		       "|   |    |    |e/cn|    |   |need|                                            |\n");
    for (i = from; i < to; i++) {
	reiserfs_warning (fp,
			  "-------------------------------------------------------------------------------\n"
			  "|%3d|%30H|%s\n", i, ih + i, i >= nr ? " DELETED" : "");

	if (I_IS_STAT_DATA_ITEM(ih+i)) {
	    is_symlink = print_stat_data (fp, bh, ih + i, 0/*all times*/);
	    continue;
	}

	if (I_IS_DIRECTORY_ITEM(ih+i)) {
	    print_directory_item (fp, fs, bh, ih+i);
	    continue;
	}

	if (I_IS_INDIRECT_ITEM(ih+i)) {
	    print_indirect_item (fp, bh, i);
	    continue;
	}

	if (I_IS_DIRECT_ITEM(ih+i)) {
	    int j = 0;
	    if (is_symlink || print_mode & PRINT_DIRECT_ITEMS) {
		reiserfs_warning (fp, "\"");
		while (j < get_ih_item_len (&ih[i])) {
		    if (B_I_PITEM(bh,ih+i)[j] == 10)
			reiserfs_warning (fp, "\\n");
		    else
			reiserfs_warning (fp, "%c", B_I_PITEM(bh,ih+i)[j]);
		    j ++;
		}
		reiserfs_warning (fp, "\"\n");
	    }
	    continue;
	}
    }
    reiserfs_warning (fp, "===================================================================\n");
    return 0;
}


void print_journal_params (FILE * fp, struct journal_params * jp)
{
    reiserfs_warning (fp, "\tDevice [0x%x]\n", get_jp_journal_dev (jp));
    reiserfs_warning (fp, "\tMagic [0x%x]\n", get_jp_journal_magic (jp));

    reiserfs_warning (fp, "\tSize %u blocks (including 1 for journal header) (first block %u)\n",
		      get_jp_journal_size (jp) + 1,
		      get_jp_journal_1st_block (jp));
    reiserfs_warning (fp, "\tMax transaction length %u blocks\n", get_jp_journal_max_trans_len (jp));
    reiserfs_warning (fp, "\tMax batch size %u blocks\n", get_jp_journal_max_batch (jp));
    reiserfs_warning (fp, "\tMax commit age %u\n", get_jp_journal_max_commit_age (jp));
    /*reiserfs_warning (fp, "\tMax transaction age %u\n", get_jp_journal_max_trans_age (jp));*/
}

/* return 1 if this is not super block */
int print_super_block (FILE * fp, reiserfs_filsys_t * fs, char * file_name,
			      struct buffer_head * bh, int short_print)
{
    struct reiserfs_super_block * sb = (struct reiserfs_super_block *)(bh->b_data);
    dev_t rdev;
    int format = 0;
    __u16 state;
    time_t last_check = get_sb_v2_lastcheck(sb);
    char last_check_buf[26];

    if (!does_look_like_super_block (sb))
	return 1;

    rdev = misc_device_rdev(file_name);

    reiserfs_warning (fp, "Reiserfs super block in block %lu on 0x%x of ",
		      bh->b_blocknr, rdev);
    switch (get_reiserfs_format (sb)) {
    case REISERFS_FORMAT_3_5:
	reiserfs_warning (fp, "format 3.5 with ");
	format = 1;
	break;
    case REISERFS_FORMAT_3_6:
	reiserfs_warning (fp, "format 3.6 with ");
	format = 2;
	break;
    default:
	reiserfs_warning (fp, "unknown format with ");
	break;
    }
    if (is_reiserfs_jr_magic_string (sb))
	reiserfs_warning (fp, "non-");
    reiserfs_warning (fp, "standard journal\n");
    if (short_print) {
	reiserfs_warning (fp, "Blocks (total/free): %u/%u by %d bytes\n",
		get_sb_block_count (sb), get_sb_free_blocks (sb), get_sb_block_size (sb));
    } else {
	reiserfs_warning (fp, "Count of blocks on the device: %u\n", get_sb_block_count (sb));
	reiserfs_warning (fp, "Number of bitmaps: %u", get_sb_bmap_nr (sb));
	if (get_sb_bmap_nr (sb) != reiserfs_fs_bmap_nr(fs))
		reiserfs_warning (fp, " (really uses %u)", reiserfs_fs_bmap_nr(fs));
	reiserfs_warning (fp, "\nBlocksize: %d\n", get_sb_block_size (sb));
	reiserfs_warning (fp, "Free blocks (count of blocks - used [journal, "
		      "bitmaps, data, reserved] blocks): %u\n", get_sb_free_blocks (sb));
	reiserfs_warning (fp, "Root block: %u\n", get_sb_root_block (sb));
    }
    reiserfs_warning (fp, "Filesystem is %sclean\n",
		      (get_sb_umount_state (sb) == FS_CLEANLY_UMOUNTED) ? "" : "NOT ");

    if (short_print)
	return 0;
    reiserfs_warning (fp, "Tree height: %d\n", get_sb_tree_height (sb));
    reiserfs_warning (fp, "Hash function used to sort names: %s\n",
		      code2name (get_sb_hash_code (sb)));
    reiserfs_warning (fp, "Objectid map size %d, max %d\n", get_sb_oid_cursize (sb),
		      get_sb_oid_maxsize (sb));
    reiserfs_warning (fp, "Journal parameters:\n");
    print_journal_params (fp, sb_jp (sb));
    reiserfs_warning (fp, "Blocks reserved by journal: %u\n",
		      get_sb_reserved_for_journal (sb));
    state = get_sb_fs_state (sb);
    reiserfs_warning (fp, "Fs state field: 0x%x:\n", state);
    if ((state & FS_FATAL) == FS_FATAL)
	reiserfs_warning (fp, "\tFATAL corruptions exist.\n");
    if ((state & FS_ERROR) == FS_ERROR)
	reiserfs_warning (fp, "\t some corruptions exist.\n");
    if ((state & IO_ERROR) == IO_ERROR)
	reiserfs_warning (fp, "\tI/O corruptions exist.\n");

    reiserfs_warning (fp, "sb_version: %u\n", get_sb_version (sb));
    if (format == 2) {
	reiserfs_warning (fp, "inode generation number: %u\n", get_sb_v2_inode_generation (sb));
	reiserfs_warning (fp, "UUID: %U\n", sb->s_uuid);
	reiserfs_warning (fp, "LABEL: %.16s\n", sb->s_label);
	reiserfs_warning (fp, "Set flags in SB:\n");
	if ((get_sb_v2_flag (sb, reiserfs_attrs_cleared)))
	    reiserfs_warning (fp, "\tATTRIBUTES CLEAN\n");
	reiserfs_warning(fp, "Mount count: %u\n",
			 get_sb_v2_mnt_count(sb));
	reiserfs_warning(fp, "Maximum mount count: ");
	if (get_sb_v2_max_mnt_count(sb) &&
	    get_sb_v2_max_mnt_count(sb) != USHRT_MAX)
		reiserfs_warning(fp, "%u\n", get_sb_v2_max_mnt_count(sb));
	else if (get_sb_v2_max_mnt_count(sb) == USHRT_MAX)
		reiserfs_warning(fp, "Administratively disabled.\n");
	else
		reiserfs_warning(fp, "Disabled. Run fsck.reiserfs(8) or use tunefs.reiserfs(8) to enable.\n");
	if (last_check) {
		ctime_r(&last_check, last_check_buf);
		reiserfs_warning(fp, "Last fsck run: %s", last_check_buf);
	} else
		reiserfs_warning(fp, "Last fsck run: Never with a version "
				 "that supports this feature.\n");
	reiserfs_warning(fp, "Check interval in days: ");
	if (get_sb_v2_check_interval(sb) &&
	    get_sb_v2_check_interval(sb) != UINT_MAX)
		reiserfs_warning(fp, "%u\n",
			 get_sb_v2_check_interval(sb) / (24*60*60));
	else if (get_sb_v2_check_interval(sb) == UINT_MAX)
		reiserfs_warning(fp, "Administratively disabled.\n");
	else
		reiserfs_warning(fp, "Disabled. Run fsck.reiserfs(8) or use tunefs.reiserfs(8) to enable.\n");
    }

    return 0;
}


void print_filesystem_state (FILE * fp, reiserfs_filsys_t * fs)
{
    reiserfs_warning (fp, "\nFilesystem state: ");
    if (reiserfs_is_fs_consistent (fs))
	reiserfs_warning (fp, "consistent\n\n");
    else
	reiserfs_warning (fp, "consistency is not checked after last mounting\n\n");
}



static int print_desc_block (FILE * fp, struct buffer_head * bh)
{
    if (memcmp(get_jd_magic (bh), JOURNAL_DESC_MAGIC, 8))
	return 1;

    reiserfs_warning (fp, "Desc block %lu (j_trans_id %ld, j_mount_id %ld, j_len %ld)\n",
		      bh->b_blocknr, get_desc_trans_id (bh),
		      get_desc_mount_id (bh), get_desc_trans_len (bh));

    return 0;
}


void print_block (FILE * fp, reiserfs_filsys_t * fs,
		  struct buffer_head * bh, ...)//int print_mode, int first, int last)
{
    va_list args;
    int mode, first, last;
    char * file_name;

    va_start (args, bh);

    if ( ! bh ) {
	reiserfs_warning (stderr, "print_block: buffer is NULL\n");
	return;
    }

    mode = va_arg (args, int);
    first = va_arg (args, int);
    last = va_arg (args, int);
    file_name = (fs) ? fs->fs_file_name : NULL ;
    if (print_desc_block (fp, bh))
	if (print_super_block (fp, fs, file_name, bh, 0))
	    if (print_leaf (fp, fs, bh, mode, first, last))
		if (print_internal (fp, bh, first, last))
		    reiserfs_warning (fp, "Block %lu contains unformatted data\n", bh->b_blocknr);
}


void print_tb (int mode, int item_pos, int pos_in_item, struct tree_balance * tb, char * mes)
{
  unsigned int h = 0;
  struct buffer_head * tbSh, * tbFh;


  if (!tb)
    return;

  printf ("\n********************** PRINT_TB for %s *******************\n", mes);
  printf ("MODE=%c, ITEM_POS=%d POS_IN_ITEM=%d\n", mode, item_pos, pos_in_item);
  printf ("*********************************************************************\n");

  printf ("* h *    S    *    L    *    R    *   F   *   FL  *   FR  *  CFL  *  CFR  *\n");
/*
01234567890123456789012345678901234567890123456789012345678901234567890123456789
       1        2         3         4         5         6         7         8
  printk ("*********************************************************************\n");
*/


  for (h = 0; h < sizeof(tb->insert_size) / sizeof (tb->insert_size[0]); h ++) {
    if (PATH_H_PATH_OFFSET (tb->tb_path, h) <= tb->tb_path->path_length &&
	PATH_H_PATH_OFFSET (tb->tb_path, h) > ILLEGAL_PATH_ELEMENT_OFFSET) {
      tbSh = PATH_H_PBUFFER (tb->tb_path, h);
      tbFh = PATH_H_PPARENT (tb->tb_path, h);
    } else {
      /*      printk ("print_tb: h=%d, PATH_H_PATH_OFFSET=%d, path_length=%d\n",
	      h, PATH_H_PATH_OFFSET (tb->tb_path, h), tb->tb_path->path_length);*/
      tbSh = 0;
      tbFh = 0;
    }
    printf ("* %u * %3lu(%2lu) * %3lu(%2lu) * %3lu(%2lu) * %5lu * %5lu * %5lu * %5lu * %5lu *\n",
	    h,
	    tbSh ? tbSh->b_blocknr : ~0ul,
	    tbSh ? tbSh->b_count : ~0ul,
	    tb->L[h] ? tb->L[h]->b_blocknr : ~0ul,
	    tb->L[h] ? tb->L[h]->b_count : ~0ul,
	    tb->R[h] ? tb->R[h]->b_blocknr : ~0ul,
	    tb->R[h] ? tb->R[h]->b_count : ~0ul,
	    tbFh ? tbFh->b_blocknr : ~0ul,
	    tb->FL[h] ? tb->FL[h]->b_blocknr : ~0ul,
	    tb->FR[h] ? tb->FR[h]->b_blocknr : ~0ul,
	    tb->CFL[h] ? tb->CFL[h]->b_blocknr : ~0ul,
	    tb->CFR[h] ? tb->CFR[h]->b_blocknr : ~0ul);
  }

  printf ("*********************************************************************\n");


  /* print balance parameters for leaf level */
  h = 0;
  printf ("* h * size * ln * lb * rn * rb * blkn * s0 * s1 * s1b * s2 * s2b * curb * lk * rk *\n");
  printf ("* %d * %4d * %2d * %2d * %2d * %2d * %4d * %2d * %2d * %3d * %2d * %3d * %4d * %2d * %2d *\n",
	  h, tb->insert_size[h], tb->lnum[h], tb->lbytes, tb->rnum[h],tb->rbytes, tb->blknum[h],
	  tb->s0num, tb->s1num,tb->s1bytes,  tb->s2num, tb->s2bytes, tb->cur_blknum, tb->lkey[h], tb->rkey[h]);


/* this prints balance parameters for non-leaf levels */
  do {
    h++;
    printf ("* %d * %4d * %2d *    * %2d *    * %2d *\n",
    h, tb->insert_size[h], tb->lnum[h], tb->rnum[h], tb->blknum[h]);
  } while (tb->insert_size[h]);

  printf ("*********************************************************************\n");


  /* print FEB list (list of buffers in form (bh (b_blocknr, b_count), that will be used for new nodes) */
  for (h = 0; h < sizeof (tb->FEB) / sizeof (tb->FEB[0]); h++)
    printf("%s%p (%lu %d)", h == 0 ? "FEB list: " : ", ", tb->FEB[h], tb->FEB[h] ? tb->FEB[h]->b_blocknr : 0,
	    tb->FEB[h] ? tb->FEB[h]->b_count : 0);
  printf ("\n");

  printf ("********************** END OF PRINT_TB *******************\n\n");
}


static void print_bmap_block (FILE * fp, int i, unsigned long block, char * map, int blocks, int silent, int blocksize)
{
    int j, k;
    int bits = blocksize * 8;
    int zeros = 0, ones = 0;


    reiserfs_warning (fp, "#%d: block %lu: ", i, block);

    blocks = blocksize * 8;

    if (misc_test_bit (0, map)) {
	/* first block addressed by this bitmap block is used */
	ones ++;
	if (!silent)
	    reiserfs_warning (fp, "Busy (%d-", i * bits);
	for (j = 1; j < blocks; j ++) {
	    while (misc_test_bit (j, map)) {
		ones ++;
		if (j == blocks - 1) {
		    if (!silent)
			reiserfs_warning (fp, "%d)\n", j + i * bits);
		    goto end;
		}
		j++;
	    }
	    if (!silent)
		reiserfs_warning (fp, "%d) Free(%d-", j - 1 + i * bits, j + i * bits);

	    while (!misc_test_bit (j, map)) {
		zeros ++;
		if (j == blocks - 1) {
		    if (!silent)
			reiserfs_warning (fp, "%d)\n", j + i * bits);
		    goto end;
		}
		j++;
	    }
	    if (!silent)
		reiserfs_warning (fp, "%d) Busy(%d-", j - 1 + i * bits, j + i * bits);

	    j --;
	end:
	    /* to make gcc 3.2 do not sware here */;
	}
    } else {
	/* first block addressed by this bitmap is free */
	zeros ++;
	if (!silent)
	    reiserfs_warning (fp, "Free (%d-", i * bits);
	for (j = 1; j < blocks; j ++) {
	    k = 0;
	    while (!misc_test_bit (j, map)) {
		k ++;
		if (j == blocks - 1) {
		    if (!silent)
			reiserfs_warning (fp, "%d)\n", j + i * bits);
		    zeros += k;
		    goto end2;
		}
		j++;
	    }
	    zeros += k;
	    if (!silent)
		reiserfs_warning (fp, "%d) Busy(%d-", j - 1 + i * bits, j + i * bits);

	    k = 0;
	    while (misc_test_bit (j, map)) {
		ones ++;
		if (j == blocks - 1) {
		    if (!silent)
			reiserfs_warning (fp, "%d)\n", j + i * bits);
		    ones += k;
		    goto end2;
		}
		j++;
	    }
	    ones += k;
	    if (!silent)
		reiserfs_warning (fp, "%d) Free(%d-", j - 1 + i * bits, j + i * bits);

	    j --;
	end2:
	    /* to make gcc 3.2 do not sware here */;
	}
    }

    reiserfs_warning (fp, "used %d, free %d\n", ones, zeros);
}


/* read bitmap of disk and print details */
void print_bmap (FILE * fp, reiserfs_filsys_t * fs, int silent)
{
    struct reiserfs_super_block * sb;
    int bmap_nr;
    int i;
    int bits_per_block;
    int blocks;
    unsigned long block;
    struct buffer_head * bh;


    sb = fs->fs_ondisk_sb;
    bmap_nr = reiserfs_fs_bmap_nr(fs);
    bits_per_block = fs->fs_blocksize * 8;
    blocks = bits_per_block;

    reiserfs_warning (fp, "Bitmap blocks are:\n");
    block = fs->fs_super_bh->b_blocknr + 1;
    for (i = 0; i < bmap_nr; i ++) {
	bh = bread (fs->fs_dev, block, fs->fs_blocksize);
	if (!bh) {
	    reiserfs_warning (stderr, "print_bmap: bread failed for %d: %lu\n", i, block);
	    continue;
	}
	if (i == bmap_nr - 1)
	    if (get_sb_block_count (sb) % bits_per_block)
		blocks = get_sb_block_count (sb) % bits_per_block;
	print_bmap_block (fp, i, block, bh->b_data, blocks, silent, fs->fs_blocksize);
	brelse (bh);

	if (spread_bitmaps (fs))
	    block = (block / (fs->fs_blocksize * 8) + 1) * (fs->fs_blocksize * 8);
	else
	    block ++;

    }
}



void print_objectid_map (FILE * fp, reiserfs_filsys_t * fs)
{
    int i;
    struct reiserfs_super_block * sb;
    __u32 * omap;


    sb = fs->fs_ondisk_sb;
    if (fs->fs_format == REISERFS_FORMAT_3_6)
	omap = (__u32 *)(sb + 1);
    else if (fs->fs_format == REISERFS_FORMAT_3_5)
	omap = (__u32 *)((struct reiserfs_super_block_v1 *)sb + 1);
    else {
	reiserfs_warning (fp, "print_objectid_map: proper signature is not found\n");
	return;
    }

    reiserfs_warning (fp, "Map of objectids (super block size %d)\n",
		      (char *)omap - (char *)sb);

    for (i = 0; i < get_sb_oid_cursize (sb); i ++) {
	if (i % 2 == 0) {
	    reiserfs_warning(fp, "busy(%u-%u) ", le32_to_cpu (omap[i]),
			     le32_to_cpu (omap[i+1]) - 1);
	} else {
	    reiserfs_warning(fp, "free(%u-%u) ", le32_to_cpu (omap[i]),
			    ((i+1) == get_sb_oid_cursize (sb)) ?
			    ~(__u32)0 : (le32_to_cpu (omap[i+1]) - 1));
	}
    }

    reiserfs_warning (fp, "\nObject id array has size %d (max %d):",
		      get_sb_oid_cursize (sb), get_sb_oid_maxsize (sb));

    for (i = 0; i < get_sb_oid_cursize (sb); i ++)
	reiserfs_warning (fp, "%s%u ", i % 2 ? "" : "*", le32_to_cpu (omap[i]));
    reiserfs_warning (fp, "\n");

}


void print_journal_header (reiserfs_filsys_t * fs)
{
    struct reiserfs_journal_header * j_head;


    j_head = (struct reiserfs_journal_header *)(fs->fs_jh_bh->b_data);
    reiserfs_warning (stdout, "Journal header (block #%lu of %s):\n"
		      "\tj_last_flush_trans_id %ld\n"
		      "\tj_first_unflushed_offset %ld\n"
		      "\tj_mount_id %ld\n",
		      fs->fs_jh_bh->b_blocknr, fs->fs_j_file_name,
		      get_jh_last_flushed (j_head),
		      get_jh_replay_start_offset (j_head),
		      get_jh_mount_id (j_head));
    print_journal_params (stdout, &j_head->jh_journal);
}


static void print_trans_element (reiserfs_filsys_t * fs, reiserfs_trans_t * trans,
				 unsigned int index, unsigned long in_journal,
				 unsigned long in_place)
{
    if (index % 8 == 0)
	reiserfs_warning (stdout, "#%d\t", index);

    reiserfs_warning (stdout, "%lu->%lu%s ",  in_journal, in_place,
		      block_of_bitmap (fs, in_place) ? "B" : "");
    if ((index + 1) % 8 == 0 || index == trans->trans_len - 1)
	reiserfs_warning (stdout, "\n");
}


void print_one_transaction (reiserfs_filsys_t * fs, reiserfs_trans_t * trans)
{
    reiserfs_warning (stdout, "Mountid %u, transid %u, desc %lu, length %u, commit %lu\n",
		      trans->mount_id, trans->trans_id,
		      trans->desc_blocknr,
		      trans->trans_len, trans->commit_blocknr);
    for_each_block (fs, trans, print_trans_element);
}


/* print all valid transactions and found dec blocks */
void print_journal (reiserfs_filsys_t * fs)
{
    if (!reiserfs_journal_opened (fs)) {
	reiserfs_warning (stderr, "print_journal: journal is not opened\n");
	return;
    }
    print_journal_header (fs);

    for_each_transaction (fs, print_one_transaction);
}
