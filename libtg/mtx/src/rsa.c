//
//  rsa.c
//  mtx
//
//  Created by Pavel Morozkin on 08.12.13.
//  Copyright (c) 2013 Pavel Morozkin. All rights reserved.
//


#include <assert.h>
#include <string.h>
#include <stdio.h>
#include <openssl/rsa.h>
#include <openssl/pem.h>
#include <openssl/rand.h>
#include <openssl/bn.h>
#include <stdio.h>

#ifdef _WIN32
#include <openssl/applink.c>
#endif

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif

#include "../include/api.h"
#include "../include/rsa.h"

unsigned rsax(unsigned char * from, int from_len, unsigned char * to, int to_len, BIGNUM * N, BIGNUM * E)
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

void rsa(unsigned char * from, size_t from_size, unsigned char * to, size_t to_size)
{
  assert(from_size == 255 || to_size == 256);
  FILE * pub = NULL;
  pub = fopen(public_key, "r");

  if (pub == NULL) {
    puts("PEM_read_RSAPublicKey returns NULL\n");
  }

  RSA * rsa = PEM_read_RSAPublicKey(pub, NULL, NULL, NULL);

  if (!rsa) {
    RSA_free(rsa);
    puts("Can not read public key from file\n");
  }

#ifdef __APPLE__
  rsax(from, (int)from_size, to, (int)to_size, rsa->n, rsa->e);
#else
  rsax(from, (int)from_size, to, (int)to_size, RSA_get0_n(rsa), RSA_get0_e(rsa));
#endif
  RSA_free(rsa);
  fclose(pub);
}

void rand_bytes(unsigned char * s, int l)
{
  RAND_bytes(s, l);
}

int pow_mod(unsigned char * y, unsigned char * g, size_t g_s, unsigned char * e, size_t e_s, unsigned char * m, size_t m_s)
{
    BIGNUM *y_ = BN_new();
		BIGNUM *g_ = BN_new();
		BIGNUM *e_ = BN_new();
		BIGNUM *m_ = BN_new();
    BN_bin2bn((unsigned char *) y, (int)m_s, y_);
    BN_bin2bn((unsigned char *) g, (int)g_s, g_);
    BN_bin2bn((unsigned char *) e, (int)e_s, e_);
    BN_bin2bn((unsigned char *) m, (int)m_s, m_);
    BN_CTX * BN_ctx;
    BN_ctx = BN_CTX_new();
    assert(BN_mod_exp(y_, g_, e_, m_, BN_ctx)); // y = g^e % m
    unsigned y_len = BN_num_bytes(y_);
    memset(y, 0x00, m_s);
    BN_bn2bin(y_, (unsigned char *) y);
    BN_CTX_free(BN_ctx);
    BN_free(y_);
    BN_free(g_);
    BN_free(e_);
    BN_free(m_);

    return y_len;
}
