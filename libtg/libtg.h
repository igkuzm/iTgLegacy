#ifndef LIBTG_H
#define LIBTG_H

#include "tl/buf.h"
#include  "tl/libtl.h"
#include <time.h>
#include <pthread.h>

// LibTG structure
typedef struct tg_ tg_t;

/* create new libtg structure */
tg_t * tg_new(
		const char *database_path, 
		int id,
		int apiId, 
		const char apiHash[33], 
		const char *pubkey_pem);

/* set on_error callback */
void tg_set_on_error(tg_t *tg,
		void *on_err_data,
		void (*on_err)(void *on_err_data, const char *err));

/* set on_log callback */
void tg_set_on_log(tg_t *tg,
		void *on_log_data,
		void (*on_log)(void *on_log_data, const char *msg));

/* set telegram server address */
void tg_set_server_address(tg_t *tg, const char *ip, int port);

/* free libtg structure and free memory */
void tg_close(tg_t *tg);

/* return allocated string with error from tl object */
char * tg_strerr(const tl_t *tl);

/* start new session */
void tg_new_session(tg_t *tg);

typedef struct tg_queue_ tg_queue_t;

/* send TL query to server and return answer */
tl_t *tg_send_query(tg_t *tg, buf_t *query);
tl_t *tg_send_query_sync(tg_t *tg, buf_t *query);
tl_t *tg_send_query_sync_with_progress(tg_t *tg, buf_t *query,
		void *progressp, 
		int (*progress)(void *progressp, int size, int total));

/* send TL query via queue manager in thread and run
 * callback on done.
 * set callback return to non-null to resend query
 * when transfer big data as chunks (like upload.getFile)
 * you need to handle chunk callback, where you set new 
 * portion of TL query to be send as chunk callback return
 * value 
 * you may handle upload/download progress via progress callback */
pthread_t tg_send_query_async(
		tg_t *tg, buf_t *query, bool multithread,
		void *userdata, void (*callback)(void *userdata, const tl_t *tl));

pthread_t tg_send_query_async_with_progress(
		tg_t *tg, buf_t *query, bool multithread,
		void *userdata, void (*callback)(void *userdata, const tl_t *tl),
		void *progressp, 
		int (*progress)(void *progressp, int size, int total));

tl_t * tg_http_send_query_with_progress(
		tg_t *tg, int dc, int port, bool maximum_limit, 
		buf_t *query,
		void *progressp, 
		int (*progress)(void *progressp, int size, int total));

tl_t * tg_http_send_query(
		tg_t *tg, buf_t *query);

/* return true if has auth key */
bool tg_has_auth_key(tg_t *tg); 

/* return authorized user tl object or throw error */
tl_user_t * tg_is_authorized(tg_t *tg);

/* return 0 if new key created */
int tg_new_auth_key(tg_t *tg);
int tg_new_auth_key1(tg_t *tg);
int tg_new_auth_key2(tg_t *tg);

/* send auth code to phone number and return sentCode 
 * tl object or thow error */
tl_auth_sentCode_t *
tg_auth_sendCode(tg_t *tg, const char *phone_number); 

/* signin with phone number and code, return authorized 
 * user tl object or thow error */
tl_user_t *
tg_auth_signIn(tg_t *tg, tl_auth_sentCode_t *sentCode, 
		const char *phone_number, const char *phone_code); 

tl_user_t *
tg_auth_check_password(tg_t *tg, const char *password);

/* all-in-one auth function */
typedef enum {
	TG_AUTH_ERROR,
	TG_AUTH_INFO,
	TG_AUTH_PHONE_NUMBER_NEEDED,
	TG_AUTH_PHONE_CODE_NEEDED,
	TG_AUTH_PASSWORD_NEEDED,
	TG_AUTH_SUCCESS,
} TG_AUTH;

/* connect to Telegram */  
int tg_connect(
		tg_t *tg,
		void *userdata,
		char * (*callback)(
			void *userdata,
			TG_AUTH auth,
			const tl_t *tl,
			const char *msg));


/* register ios device for push notifications */
int tg_account_register_ios(
		tg_t *tg, const char *token, bool development);

#endif /* ifndef LIBTG_H */
