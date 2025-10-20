#ifndef TG_TRANSPORT_H
#define TG_TRANSPORT_H

#include "../tg/tg.h"

buf_t tg_encrypt    (tg_t *tg, buf_t b, bool enc);
buf_t tg_decrypt    (tg_t *tg, buf_t b, bool enc);
buf_t tg_header     (tg_t *tg, buf_t b, bool enc, 
										bool content, uint64_t *msgid);
buf_t tg_deheader   (tg_t *tg, buf_t b, bool enc);
buf_t tg_transport  (tg_t *tg, buf_t b);
buf_t tg_detransport(tg_t *tg, buf_t b);
buf_t tg_ack(tg_t *tg);

tl_t * tg_handle_deserialized_message(tg_t *tg, tl_t *tl);
tl_t * tg_handle_serialized_message(tg_t *tg, buf_t msg);

#endif /* ifndef TG_TRANSPORT_H */
