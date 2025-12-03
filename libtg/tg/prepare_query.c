#include "transport.h"
#if INTPTR_MAX == INT32_MAX
    #define THIS_IS_32_BIT_ENVIRONMENT
		#define _LD_ "%lld"
#elif INTPTR_MAX == INT64_MAX
    #define THIS_IS_64_BIT_ENVIRONMENT
		#define _LD_ "%ld"
#else
    #error "Environment not 32 or 64-bit."
#endif


buf_t tg_prepare_query(tg_t *tg, buf_t *query, bool enc, uint64_t *msgid)
{
	ON_LOG(tg, "%s", __func__);
	buf_t h = tg_header(tg, *query, enc, true, msgid);
	
	buf_t e = tg_encrypt(tg, h, enc);
	buf_free(h);

	buf_t t = tg_transport(tg, e);
	buf_free(e);

	if (t.size == 0)
		ON_ERR(tg, "%s: error for msgid: "_LD_"", 
				__func__, *msgid);

	return t;
}
