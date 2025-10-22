#ifndef TG_ERRORS_H
#define TG_ERRORS_H
/*#include "auth.h"*/
#include "dc.h"
#include "tg.h"

#define RPC_ERROR(tl_) \
	STRING_T_TO_STR(((tl_rpc_error_t *)tl_)->error_message_) 

const dc_t * 
tg_error_phone_migrate(tg_t*, const char *);

const dc_t * 
tg_error_file_migrate(tg_t*, const char *);

int tg_error_flood_wait(tg_t *tg, const char *error);

//AUTH_ERR_CODE tg_error_auth_err_code(tg_t *tg, const char *error);

#endif /* ifndef TG_ERRORS_H */
