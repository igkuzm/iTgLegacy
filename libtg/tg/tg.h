#ifndef TG_H_
#define TG_H_
#include <pthread.h>
#include <stdint.h>
#include <sqlite3.h>
#include <string.h>
#include "../libtg.h"
#include "../tl/str.h"
#include "list.h"

#define SERVER_IP   "149.154.167.50"
//#define SERVER_IP   "149.154.175.57"
#define SERVER_PORT 443
#define DEFAULT_DC 2

typedef int socet_t;

struct tg_ {
	int id;
	int apiId;
	char apiHash[33];
	char database_path[BUFSIZ];
	pthread_mutex_t databasem;
	const char *pubkey;
	char ip[16];
	int port;
	list_t *queue;
	pthread_mutex_t queuem;
	pthread_mutex_t send_query;
	socet_t socket;
	pthread_mutex_t socket_mutex;
	tl_config_t *config;
	void *on_err_data;
	void (*on_err)(void *on_err_data, const char *err);
	void *on_log_data;
	void (*on_log)(void *on_log_data, const char *msg);
	void *on_update_data;
	void (*on_update)(void *on_update_data, int type, void *data);
	int seqn;
	pthread_mutex_t seqnm;
	buf_t key;
	uint64_t key_id;
	buf_t salt;
	buf_t ssid;
	uint64_t fingerprint;
	uint64_t *msgids; 
	pthread_mutex_t msgidsm;
	uint64_t *todrop; 
	pthread_mutex_t todropm;
	time_t timediff;
};


int database_init(tg_t *tg, const char *database_path);
buf_t auth_key_from_database(tg_t *tg);
char * phone_number_from_database(tg_t *tg);
char * auth_tokens_from_database(tg_t *tg);

void update_hash(uint64_t *hash, uint32_t msg_id);

uint64_t dialogs_hash_from_database(tg_t *tg);
int dialogs_hash_to_database(tg_t *tg, uint64_t hash);

uint64_t messages_hash_from_database(tg_t *tg, uint64_t peer_id);
int messages_hash_to_database(tg_t *tg, uint64_t peer_id, uint64_t hash);

buf_t initConnection(tg_t *tg, buf_t query);

char *photo_file_from_database(tg_t *tg, uint64_t photo_id);
int photo_to_database(tg_t *tg, uint64_t photo_id, const char *data);
char *peer_photo_file_from_database(tg_t *tg, 
		uint64_t peer_id, uint64_t photo_id);
int peer_photo_to_database(tg_t *tg, 
		uint64_t peer_id, uint64_t photo_id,
		const char *data);

int phone_number_to_database(
		tg_t *tg, const char *phone_number);

int auth_token_to_database(tg_t *tg, const char *auth_token);

int ip_address_to_database(tg_t *tg, const char *ip);
char *ip_address_from_database(tg_t *tg);

int auth_key_to_database(
		tg_t *tg, buf_t auth_key);

void tg_add_msgid(tg_t*, uint64_t);

tl_t * tg_send_query_(tg_t *tg, buf_t s, bool encrypt);
tl_t * tg_send_query_to_net(
		tg_t *tg, buf_t query, bool enc, int sockfd);

#define ON_UPDATE(tg, type, data)\
	({if (tg->on_update){ \
		tg->on_update(tg->on_update_data, type, data); \
	 }\
	})

#define ON_ERR(tg, ...)\
	({if (tg->on_err){ \
		struct str _s; str_init(&_s); str_appendf(&_s, __VA_ARGS__);\
		if (!strstr(_s.str, "duplicate column name:")) \
			tg->on_err(tg->on_err_data, _s.str); \
		free(_s.str);\
	 }\
	})

#define ON_LOG(tg, ...)\
	({if (tg->on_log){ \
		struct str _s; str_init(&_s); str_appendf(&_s, __VA_ARGS__);\
		tg->on_log(tg->on_log_data, _s.str); \
		free(_s.str);\
	 }\
	})

#define ON_LOG_BUF(tg, buf, ...)\
	({if (tg->on_log){ \
		struct str _s; str_init(&_s); str_appendf(&_s, __VA_ARGS__);\
		char *dump = buf_sdump(buf);\
		str_append(&_s, dump, strlen(dump));\
		free(dump);\
		tg->on_log(tg->on_log_data, _s.str); \
		free(_s.str);\
	 }\
	})

buf_t image_from_photo_stripped(buf_t photoStreppedData);
char *image_from_svg_path(buf_t encoded);

tl_config_t *tg_get_config(tg_t *tg);
const char *tg_ip_address_for_dc(tg_t *tg, int dc);

buf_t tg_prepare_query(tg_t *tg, buf_t *query, bool enc, 
											 uint64_t *msgid);

buf_t tg_mtp_message(tg_t *tg, buf_t *payload, 
		uint64_t *msgid, bool content);

void tg_rpc_drop_answer(tg_t *tg, uint64_t msg_id);
void tg_add_todrop(tg_t *tg, uint64_t msgid);
int tg_to_drop(tg_t *tg, buf_t *buf);

tl_t *tg_tl_from_gzip(tg_t *tg, tl_t *tl);

time_t ntp_time_diff();

#define tg_mutex_lock(_tg, _mutex, _ret) \
	if (pthread_mutex_lock(_mutex)){ \
		ON_ERR(_tg, "%s: can't lock mutex: %s", __func__, #_mutex);\
		_ret; \
	}

#define tg_mutex_unlock(_mutex) \
	pthread_mutex_unlock(_mutex);

#endif /* ifndef TG_H_ */
