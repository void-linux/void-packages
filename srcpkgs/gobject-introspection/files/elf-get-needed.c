/*
 * Copyright © 2019-2023 Collabora Ltd.
 * SPDX-License-Identifier: MIT
 *
 * Use libelf to parse ELF headers for DT_NEEDED, and fake the output
 * format of ldd closely enough that GObject-Introspection can parse it.
 *
 * Limitations when compared with real ldd:
 * - Only direct dependencies are output: unlike ldd, this is not recursive.
 *   For GObject-Introspection this is what we ideally want anyway.
 * - Only bare SONAMEs are output, no paths or other extraneous information.
 *
 * https://salsa.debian.org/gnome-team/gobject-introspection/-/blob/debian/latest/debian/elf-get-needed.c
 * https://gitlab.gnome.org/GNOME/gobject-introspection/-/issues/482
 */

#include <fcntl.h>
#include <stddef.h>
#include <stdio.h>
#include <unistd.h>

#include <elf.h>
#include <gelf.h>

#if 0
#define trace(...) fprintf(stderr, __VA_ARGS__)
#else
#define trace(...) do {} while (0)
#endif

int
main (int argc,
      char **argv)
{
  const char *library;
  Elf *elf = NULL;
  Elf_Scn *scn = NULL;
  GElf_Shdr shdr_mem;
  GElf_Shdr *shdr = NULL;
  size_t phnum;
  size_t i;
  Elf_Data *data;
  uintptr_t needed_offset = (uintptr_t) -1;
  const char *needed;
  size_t sh_entsize;
  int fd;

  if (argc != 2)
    {
      fprintf (stderr, "Usage: %s LIBRARY\n", argv[0]);
      return 2;
    }

  library = argv[1];

  if (elf_version (EV_CURRENT) == EV_NONE)
    {
      perror ("elf_version(EV_CURRENT)");
      return 1;
    }

  if ((fd = open (library, O_RDONLY | O_CLOEXEC, 0)) < 0)
    {
      perror (library);
      return 1;
    }

  if ((elf = elf_begin (fd, ELF_C_READ, NULL)) == NULL)
    {
      fprintf (stderr, "Error reading library %s: %s",
               library, elf_errmsg (elf_errno ()));
      return 1;
    }

  if (elf_getphdrnum (elf, &phnum) < 0)
    {

      fprintf (stderr, "Unable to determine the number of program headers: %s\n",
               elf_errmsg (elf_errno ()));

      return 1;
    }

  trace ("phnum=%zu\n", phnum);

  for (i = 0; i < phnum; i++)
    {
      GElf_Phdr phdr_mem;
      GElf_Phdr *phdr = gelf_getphdr (elf, i, &phdr_mem);

      if (phdr != NULL && phdr->p_type == PT_DYNAMIC)
        {
          scn = gelf_offscn (elf, phdr->p_offset);
          trace ("scn=%p\n", scn);

          if (scn == NULL)
            {
              fprintf (stderr, "Unable to get the section: %s\n",

                       elf_errmsg (elf_errno ()));

              return 1;
            }

          shdr = gelf_getshdr (scn, &shdr_mem);
          trace ("shdr=%p, shdr_mem=%p\n", shdr, &shdr_mem);

          if (shdr == NULL)
            {
              fprintf (stderr, "Unable to get the section header: %s\n",

                       elf_errmsg (elf_errno ()));

              return 1;
            }
          break;
        }
    }

  if (shdr == NULL)
    {
      fprintf (stderr, "Unable to find the section header\n");
      return 1;
    }

  data = elf_getdata (scn, NULL);

  if (data == NULL)
    {
      fprintf (stderr, "Unable to get the dynamic section data: %s\n",
               elf_errmsg (elf_errno ()));

      return 1;
    }

  trace ("data=%p\n", data);

  sh_entsize = gelf_fsize (elf, ELF_T_DYN, 1, EV_CURRENT);
  trace ("sh_entsize=%zu\n", sh_entsize);

  for (i = 0; i < shdr->sh_size / sh_entsize; i++)
    {
      GElf_Dyn dyn_mem;
      GElf_Dyn *dyn = gelf_getdyn (data, i, &dyn_mem);

      if (dyn == NULL)
        break;

      if (dyn->d_tag == DT_NEEDED)
        printf ("%s\n", elf_strptr (elf, shdr->sh_link, dyn->d_un.d_ptr));
    }

  elf_end (elf);
  close (fd);
  return 0;
}
