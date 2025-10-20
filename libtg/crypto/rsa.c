#include "../tg/tg.h"
#include "cry.h"
#include "hsh.h"
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/bn.h>
#include <assert.h>
#include "../tl/serialize.h"

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif

static RSA *read_pubkey(tg_t *tg)
{
	FILE * pub = fopen(tg->pubkey, "r");
  if (pub == NULL) {
    ON_ERR(tg,
				"%s: can not read public key from file: '%s'",
				 __func__, tg->pubkey);
		return NULL;
  }

  RSA * rsa = 
		PEM_read_RSAPublicKey(pub, NULL, NULL, NULL);
  if (!rsa) {
		fclose(pub);
    RSA_free(rsa);
    ON_ERR(tg,
				"%s: PEM_read_RSAPublicKey: '%s' returns NULL",
				__func__, tg->pubkey);
		return NULL;
  }

	fclose(pub);
	return rsa;
}

uint64_t tg_cry_rsa_fpt(tg_t *tg){
 /* key fingerprint (64 lower-order bits of SHA1
	* (server_public_key); the public key is represented as a
	* bare type rsa_public_key n:string e:string =
	* RSAPublicKey, where, as usual, n and e are numbers in
	* big endian format serialized as strings of bytes,
	* following
	* which SHA1 is computed) received by the server. */

	RSA *rsa = read_pubkey(tg);
	if (!rsa)
		return 1;

#ifdef __APPLE__
	const BIGNUM *n = rsa->n;
	const BIGNUM *e = rsa->e;
#else
	const BIGNUM *n = RSA_get0_n(rsa);
	const BIGNUM *e = RSA_get0_e(rsa);
#endif

	buf_t a;
	buf_init(&a);
	a.size = BN_bn2bin(n, a.data);
	buf_t astr = serialize_bytes(a.data, a.size);
	buf_free(a);

	buf_t b;
	buf_init(&b);
	b.size = BN_bn2bin(e, b.data);
	buf_t bstr = serialize_bytes(b.data, b.size);
	buf_free(b);

	buf_t buf = buf_cat(astr, bstr);
	buf_t buf_hash = tg_hsh_sha1(buf);
	buf_free(astr); buf_free(bstr);

	// get lower 64bit
	int c = 20 - 8; // 160 - 64 SHA1 has 164 bit
	buf_t lower = 
		buf_add(buf_hash.data + c, 8);
	buf_free(buf_hash);

	uint64_t fingerprint = buf_get_ui64(lower);
	buf_free(lower);

	return fingerprint;
}

int tg_cry_rsa_cmp(tg_t *tg, buf_t buf)
{
	RSA *rsa = read_pubkey(tg);
	if (!rsa)
		return 1;

	BIGNUM *a = BN_new();
  BN_bin2bn(buf.data, buf.size, a);

#ifdef __APPLE__
	const BIGNUM *b = rsa->n;
#else
	const BIGNUM *b = RSA_get0_n(rsa);
#endif
	RSA_free(rsa);
	
	int cmp = BN_cmp(a, b);
	
	BN_free(a);
	return cmp;
}

buf_t tg_cry_rsa_enc(tg_t *tg, buf_t buf)
{
	buf_t ret;
	buf_init(&ret);
	if (buf.size > ret.asize)
		buf_realloc(&ret, buf.size + 1);
	
	RSA *rsa = read_pubkey(tg);
	if (!rsa)
		return ret;
	
	BIGNUM *a = BN_new();
  BN_bin2bn(buf.data, buf.size, a);
	
#ifdef __APPLE__
	const BIGNUM *n = rsa->n;
	const BIGNUM *e = rsa->e;
#else
	const BIGNUM *n = RSA_get0_n(rsa);
	const BIGNUM *e = RSA_get0_e(rsa);
#endif
  
	BN_CTX * BN_ctx = BN_CTX_new();
	BIGNUM *r = BN_new();
  assert(BN_mod_exp(r, a, e, n, BN_ctx)); // r = a^e % n
	int len = BN_bn2bin(r, (unsigned char *) ret.data);
	ret.size = len;

	BN_free(a);
	BN_free(r);
	RSA_free(rsa);

	return ret;
}

unsigned tg_rsax(unsigned char * from, int from_len, unsigned char * to, int to_len, const BIGNUM * N, const BIGNUM * E)
{
  BIGNUM *x = BN_new();
	BIGNUM *y = BN_new();
  BN_CTX * BN_ctx;
  BN_ctx = BN_CTX_new();
  BN_bin2bn((unsigned char *) from, from_len, x);
  BIO * wbio = NULL;
  wbio = BIO_new(BIO_s_file());
  BIO_set_fp(wbio, stdout, BIO_NOCLOSE);
  //BN_print(wbio, &x);
  //puts("");
  //BN_print(wbio, N);
  //puts("");
  //BN_print(wbio, E);
  assert(BN_mod_exp(y, x, E, N, BN_ctx)); // y = x^E % N
  //BN_print(wbio, &y);
  BIO_free(wbio);
  unsigned y_len = BN_num_bytes(y); //printf("y_len: %d\n", y_len);
  memset(to, 0x00, to_len);
  BN_bn2bin(y, (unsigned char *) to);
  BN_CTX_free(BN_ctx);
  BN_free(x);
  BN_free(y);

  return y_len;
}

void tg_rsa(tg_t *tg, unsigned char * from, size_t from_size, unsigned char * to, size_t to_size)
{
  assert(from_size == 255 || to_size == 256);
  FILE * pub = NULL;
  pub = fopen(tg->pubkey, "r");

  if (pub == NULL) {
    puts("PEM_read_RSAPublicKey returns NULL\n");
  }

  RSA * rsa = PEM_read_RSAPublicKey(pub, NULL, NULL, NULL);

  if (!rsa) {
    RSA_free(rsa);
    puts("Can not read public key from file\n");
  }

#ifdef __APPLE__
  tg_rsax(from, (int)from_size, to, (int)to_size, rsa->n, rsa->e);
#else
  tg_rsax(from, (int)from_size, to, (int)to_size, RSA_get0_n(rsa), RSA_get0_e(rsa));
#endif
  RSA_free(rsa);
  fclose(pub);
}

buf_t tg_cry_rsa_e(tg_t *tg, buf_t b)
{
  buf_t r = {};
	buf_init(&r);
  r.size = 256;

  tg_rsa(tg, b.data, b.size, r.data, r.size);

  return r;
}
