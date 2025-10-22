#ifndef TG_ANSWER_H
#define TG_ANSWER_H
#include "tg.h"
int tg_parse_answer(tg_t *tg, tl_t *tl, uint64_t msg_id,
		void *ptr, int (*callback)(void *ptr, const tl_t *tl));
#endif /* ifndef TG_ANSWER_H */
