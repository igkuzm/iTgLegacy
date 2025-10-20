/**
 * File              : hsh.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 21.11.2024
 * Last Modified Date: 20.10.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "sha1.h"
/*#include "sha256.h"*/
#include "hsh.h"
#include <openssl/sha.h>

buf_t tg_hsh_sha1(buf_t b)
{
  buf_t h;
	buf_init(&h);
	SHA1(b.data, b.size, h.data);
	/* sha1(b.data, b.size, h.data); */
  h.size = 20;

  return h;
}

buf_t tg_hsh_sha256(buf_t b)
{
  buf_t h;
	buf_init(&h);
	SHA256(b.data, b.size, h.data);
  /*sha256_bytes(b.data, b.size, h.data);*/
  h.size = 32;

  return h;
}
