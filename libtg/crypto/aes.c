/**
 * File              : aes.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 21.11.2024
 * Last Modified Date: 24.11.2024
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "cry.h"
#include <openssl/aes.h>

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif

buf_t tg_cry_aes_e(buf_t b, buf_t k, buf_t iv)
{
  buf_t r;
	buf_init(&r);
	if (b.size > r.size)
		buf_realloc(&r, b.size * 3);
  
	AES_KEY key;
  AES_set_encrypt_key(
			k.data, 256, &key);

  AES_ige_encrypt(
			b.data, 
			r.data, 
			b.size, 
			&key, 
			iv.data, 
			AES_ENCRYPT);

  r.size = b.size;
  return r;
}

buf_t tg_cry_aes_d(buf_t b, buf_t k, buf_t iv)
{
	buf_t r;
	buf_init(&r);
	if (b.size > r.size)
		buf_realloc(&r, b.size * 3);
  
	AES_KEY key;
  AES_set_decrypt_key(
			k.data, 256, &key);

  AES_ige_encrypt(
			b.data, 
			r.data, 
			b.size, 
			&key, 
			iv.data, 
			AES_DECRYPT);

  r.size = b.size;
  return r;
}

//void tg_rand_bytes(unsigned char * s, int l)
//{
  //RAND_bytes(s, l);
//}
