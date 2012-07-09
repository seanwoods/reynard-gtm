#include <stdlib.h>
#include <stdio.h>
#include "gcrypt.h"
#include "gtmxc_types.h"

/* @gtmxc-module digest */

/* @gtmxc sha1: void sha1(I:xc_char_t*, O:xc_char_t*[41]) */
void sha1 (int count, char *val, char *out) {
    int msg_length = strlen(val);
    int hash_length = gcry_md_get_algo_dlen(GCRY_MD_SHA1);
    unsigned char hash[hash_length];

    gcry_md_hash_buffer(GCRY_MD_SHA1, hash, val, msg_length);

    char *p = out;
    int i;
    
    memset(out, 0, sizeof (char) * 41);

    for (i = 0; i < hash_length; i++, p+=2) {
        snprintf(p, 3, "%02x", hash[i]);
    }
}
