#ifndef TG_HTTP_H
#define TG_HTTP_H value

#include "tg.h"

/* send buf_t data and rescive answer */
extern buf_t tg_http_send_query_with_progress(
		tg_t *tg, int dc, int port, bool maximum_limit, 
		buf_t *query,
		void *progressp, 
		int (*progress)(void *progressp, int size, int total));

#endif /* ifndef TG_HTTP_H */
