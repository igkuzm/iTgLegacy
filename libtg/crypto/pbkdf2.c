#include "pbkdf2.h"
#include <openssl/evp.h>
#include <openssl/hmac.h>
#include <assert.h>
#include <string.h>

buf_t tg_pbkdf2_sha512(
		buf_t password, buf_t salt, int iteration_count)
{
	assert(iteration_count > 0);
	
	const EVP_MD *evp_md = EVP_sha512();
  int hash_size = EVP_MD_size(evp_md);
	
	buf_t dest = buf_new();
	dest.size = hash_size;
	
//#if OPENSSL_VERSION_NUMBER < 0x10000000L
	fprintf(stderr, "use HMAC_CTX\n");
	HMAC_CTX ctx;
  HMAC_CTX_init(&ctx);
  unsigned char counter[4] = {0, 0, 0, 1};
  HMAC_Init_ex(&ctx, password.data, password.size, evp_md, NULL);
  HMAC_Update(&ctx, salt.data, salt.size);
  HMAC_Update(&ctx, counter, 4);
  HMAC_Final(&ctx, dest.data, NULL);
  HMAC_CTX_cleanup(&ctx);

	if (iteration_count > 1) {
		unsigned char buf[64];
		memcpy(buf, dest.data, dest.size);
		for (int iter = 1; iter < iteration_count; iter++) {
			if (HMAC(evp_md, password.data, password.size,
						buf, hash_size, buf, NULL) == NULL) 
			{
				perror("Failed to HMAC");
				return dest; 
			}
			int i;
			for (i = 0; i < hash_size; i++) {
				dest.data[i] = dest.data[i] ^ buf[i];
			}
		}
	}
//#else
//	fprintf(stderr, "use PKCS5_PBKDF2_HMAC\n");
//	if (PKCS5_PBKDF2_HMAC(
//			(char *)password.data, password.size, 
//			salt.data, salt.size, 
//			iteration_count, evp_md, 
//			hash_size, dest.data) != 1)
//	{
//		perror("Failed to HMAC");
//		return dest; 
//	}
//#endif
	
	dest.size = hash_size;
	return dest; 
}
