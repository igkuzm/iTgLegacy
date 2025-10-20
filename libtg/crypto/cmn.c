/**
 * File              : cmn.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 24.11.2024
 * Last Modified Date: 25.11.2024
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "cmn.h"
#include "fact.h"

void tg_cmn_fact(uint64_t pq, uint32_t * p, uint32_t * q)
{
  factor(pq, p, q);
}

//int tg_pow_mod(unsigned char * y, unsigned char * g, size_t g_s, unsigned char * e, size_t e_s, unsigned char * m, size_t m_s)
//{
		//BIGNUM *y_ = BN_new();
		//BIGNUM *g_ = BN_new();
		//BIGNUM *e_ = BN_new();
		//BIGNUM *m_ = BN_new();
		//BN_bin2bn((unsigned char *) y, (int)m_s, y_);
		//BN_bin2bn((unsigned char *) g, (int)g_s, g_);
		//BN_bin2bn((unsigned char *) e, (int)e_s, e_);
		//BN_bin2bn((unsigned char *) m, (int)m_s, m_);
		//BN_CTX * BN_ctx;
		//BN_ctx = BN_CTX_new();
		//assert(BN_mod_exp(y_, g_, e_, m_, BN_ctx)); // y = g^e % m
		//unsigned y_len = BN_num_bytes(y_);
		//memset(y, 0x00, m_s);
		//BN_bn2bin(y_, (unsigned char *) y);
		//BN_CTX_free(BN_ctx);
		//BN_free(y_);
		//BN_free(g_);
		//BN_free(e_);
		//BN_free(m_);

		//return y_len;
//}

//buf_t cmn_pow_mod(buf_t g, buf_t e, buf_t m)
//{
  //if (e.size != m.size || e.size != 256 || e.size != 256) {
    //printf("can't pow_mod\n");
  //}

  //buf_t r;

  //int l = tl_pow_mod(r.data, g.data, g.size, e.data, e.size, m.data, m.size);

  //if (!l) {
    //printf("pow_mod failed\n");
  //}

  //r.size = l;

  //return r;
//}


