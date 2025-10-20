#include "transport.h"

buf_t tg_prepare_query(tg_t *tg, buf_t *query, bool enc, uint64_t *msgid)
{
	ON_LOG(tg, "%s", __func__);
	buf_t h = tg_header(tg, *query, enc, true, msgid);
	
	buf_t e = tg_encrypt(tg, h, enc);
	buf_free(h);

	buf_t t = tg_transport(tg, e);
	buf_free(e);

	return t;
}
