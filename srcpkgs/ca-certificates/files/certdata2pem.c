/* Copyright (C) 2013, Felix Janda <felix.janda@posteo.de>

Permission to use, copy, modify, and/or distribute this software for
any purpose with or without fee is hereby granted, provided that the
above copyright notice and this permission notice appear in all copies.

SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <err.h>

void xwrite(FILE *f, void *p, size_t size)
{
  if (fwrite(p, 1, size, f) != size) err(1, 0);
}

int main(void)
{
  FILE *f;
  char cert[4096], ecert[4096*4/3 + 100];
  char *line = 0, *tmp, *filename, *label, *pcert = 0;
  ssize_t len;
  size_t size, certsize;
  int trust;
  char **blacklist = 0, **node;

  filename = "./blacklist.txt";
  if (!(f = fopen(filename, "r"))) err(1, "%s", filename);
  while ((len = getline(&line, &size, f)) != -1) {
    if ((line[0] != '#') && (len > 1)) {
      if (!(node = malloc(sizeof(void*) + len))) err(1, 0);
      *node = (char*)blacklist;
      memcpy(node + 1, line, len);
      blacklist = node;
    }
  }
  fclose(f);

  filename = "./certdata.txt";
  if (!(f = fopen(filename, "r"))) err(1, "%s", filename);
  while ((len = getline(&line, &size, f)) != -1) {
    tmp = line;
    if (line[0] == '#') continue;
    if (pcert) {
      if (!strcmp(line, "END\n")) {
        char *base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                       "abcdefghijklmnopqrstuvwxyz0123456789+/";
        size_t i, j, k, val;

        for (i = 0, val = 0, tmp = ecert; i < (size_t)(pcert - cert); i++) {
          val = (val << 8) + (unsigned char)cert[i];
          if (i % 3 == 2) {
            for (j = 0; j < 4; j++, val >>= 6) tmp[3 - j] = base64[val & 0x3f];
            tmp += 4;
          }
          if (i && !(i % 48)) {
            *tmp = '\n';
            tmp++;
          }
        }
        if (k = i % 3) {
          tmp[2] = '=';
          tmp[3] = '=';
          val <<= 6 - 2*k;
          for (j = 0; j < k + 1; j++, val >>= 6) tmp[k - j] = base64[val & 0x3f];
          tmp += 4;
        }
        certsize = tmp - ecert;
        pcert = 0;
      } else while (sscanf(tmp, "\\%hho", pcert) == 1) pcert++, tmp += 4;
    } else if (!memcmp(line, "CKA_LABEL UTF8 ", 15)) {

      char *p2, *tmp2;
      len -= 15;
      if (!(label = malloc(len))) err(1, 0);
      memcpy(label, line + 15, len);
      trust = 0;
      for (node = blacklist; node; node = (char**)*node)
        if (!strcmp(label, (char*)(node + 1))) trust = 4;
      if (!(p2 = malloc(len + 2))) err(1, 0);
      for (tmp = label + 1, tmp2 = p2; *tmp != '"'; tmp++, tmp2++) {
        switch (*tmp) {
        case '\\':
          if (sscanf(tmp, "\\x%hhx", tmp2)!=1) errx(1, "Bad triple: %s\n", tmp);
          tmp += 3;
          break;
        case '/':
        case ' ':
          *tmp2 = '_';
          break;
        case '(':
        case ')':
          *tmp2 = '=';
          break;
        default:
          *tmp2 = *tmp;
        }
      }
      strcpy(tmp2, ".crt");
      free(label);
      label = p2;
    } else if (!strcmp(line, "CKA_VALUE MULTILINE_OCTAL\n")) pcert = cert;
    else if (!memcmp(line, "CKA_TRUST_SERVER_AUTH CK_TRUST CKT_NSS_", 39)) {
      tmp += 39;
      if (!strcmp(tmp, "TRUSTED_DELEGATOR\n")) trust |= 1;
      else if (!strcmp(tmp, "NOT_TRUSTED\n")) trust |= 2;
    } else if (!memcmp(line,
                       "CKA_TRUST_EMAIL_PROTECTION CK_TRUST CKT_NSS_", 44)) {
      tmp += 44;
      if (!strcmp(tmp, "TRUSTED_DELEGATOR\n")) trust |= 1;
      else if (!strcmp(tmp, "NOT_TRUSTED\n")) trust |= 2;
      if (!trust) printf("Ignoring %s\n", label);
      if (trust == 1) {
        FILE *out;
        if (!(out = fopen(label, "w"))) err(1, "%s", label);
        xwrite(out, "-----BEGIN CERTIFICATE-----\n", 28);
        xwrite(out, ecert, certsize);
        xwrite(out, "\n-----END CERTIFICATE-----\n", 27);
        fclose(out);
      }
    }
  }
  fclose(f);
  
  while (blacklist) {
    node = (char**)*blacklist;
    free(blacklist);
    blacklist = node;
  }
  free(line);
  free(label);
  return 0;
}