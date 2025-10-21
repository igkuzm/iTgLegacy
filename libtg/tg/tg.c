#include "../libtg.h"
#include "../tl/alloc.h"
#include "peer.h"
#include "tg.h"
#include "net.h"
#include "queue.h"
#include "../crypto/cry.h"
#include "../crypto/hsh.h"
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

tg_t *tg_new(
		const char *database_path,
		int id,
		int apiId, 
		const char *apiHash, 
		const char *pem)
{
	if (!database_path)
		return NULL;

	// allocate struct
	tg_t *tg = NEW(tg_t, return NULL);	

	strncpy(tg->database_path,
		 	database_path, BUFSIZ-1);

	tg->id = id;
	
	// connect to SQL
	if (database_init(tg, database_path))
		return NULL;
	
	// set apiId and apiHash
	tg->apiId = apiId;
	strncpy(tg->apiHash, apiHash, 33);

	// set public_key
	tg->pubkey = pem;

	// set server address
	char *ip = ip_address_from_database(tg);
	if (ip){
		strncpy(tg->ip, ip,
			sizeof(tg->ip) - 1);
		free(ip);
	}
	else
		strncpy(tg->ip, SERVER_IP,
			sizeof(tg->ip) - 1);
	
	// set port
	tg->port = SERVER_PORT;

	// set auth_key
	tg->key = auth_key_from_database(tg);
	if (tg->key.size){
		// auth key id
		buf_t key_hash = tg_hsh_sha1(tg->key);
		buf_t auth_key_id = 
			buf_add(key_hash.data + 12, 8);
		tg->key_id = buf_get_ui64(auth_key_id);
		buf_free(key_hash);
		buf_free(auth_key_id);
	}

	// start new seqn
	tg->seqn = 0;

	// start queue manager
	/*if (tg_start_send_queue_manager(tg))*/
		/*return NULL;*/
	/*if (tg_start_receive_queue_manager(tg))*/
		/*return NULL;*/
	/*tg->queue_sockfd = -1;*/

	// init queue manager
	tg->queue = NULL;		
	if (pthread_mutex_init(
				&tg->queuem, NULL))
	{
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}
	
	if (pthread_mutex_init(
				&tg->msgidsm, NULL))
	{
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}

	if (pthread_mutex_init(
				&tg->databasem, NULL))
	{
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}

	if (pthread_mutex_init(
				&tg->seqnm, NULL))
	{
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}

	if (pthread_mutex_init(
				&tg->send_query, NULL))
	{
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}

	if (pthread_mutex_init(
				&tg->todropm, NULL))
	{
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}



	return tg;
}

void tg_close(tg_t *tg)
{
	// close Telegram
	
	// free
	free(tg);
}

void tg_set_on_error(tg_t *tg,
		void *on_err_data,
		void (*on_err)(void *on_err_data, const char *err))
{
	if (tg){
		tg->on_err = on_err;
		tg->on_err_data = on_err_data;
	}
}

void tg_set_on_log(tg_t *tg,
		void *on_log_data,
		void (*on_log)(void *on_log_data, const char *msg))
{
	if (tg){
		tg->on_log = on_log;
		tg->on_log_data = on_log_data;
	}
}

void tg_set_server_address(tg_t *tg, const char *ip, int port)
{
	if (tg){
		strncpy(tg->ip, ip,
			 	sizeof(tg->ip) - 1);
		tg->port = port;
	}
}

void update_hash(uint64_t *hash, uint32_t msg_id){
	int k;
	uint64_t h = 0;
	if (hash)
		h = *hash;

	h = h ^ (h >> 21);
	h = h ^ (h << 35);
	h = h ^ (h >> 4);
	h = h + msg_id;
	
	if (hash)
		*hash = h;
}

int tg_account_register_ios(tg_t *tg, const char *token, bool development)
{
	int ret = 1;
	buf_t secret = buf_new();
	buf_t app_sandbox = development?tl_boolTrue():tl_boolFalse();
	buf_t query = tl_account_registerDevice(
			NULL, 
			1, 
			token, 
			&app_sandbox, 
			&secret, 
			NULL, 0); 
	buf_free(secret);
	buf_free(app_sandbox);
	
	tl_t *tl = tg_send_query_sync(tg, &query);
	buf_free(query);
	
	if (tl == NULL)
		return 1;

	if (tl->_id == id_boolTrue)
		ret = 0;
	
	// free tl
	tl_free(tl);
	
	return ret;
}

tl_config_t *tg_get_config(tg_t *tg){
	buf_t query = tl_help_getConfig();
	tl_t *tl = tg_send_query_sync(tg, &query);
	buf_free(query);
	if (tl == NULL)
		return NULL;

	if (tl->_id != id_config)
		return NULL;

	return (tl_config_t *)tl;
}

const char *tg_ip_address_for_dc(tg_t *tg, int dc){
	if (!tg->config){
		ON_ERR(tg, "%s: no config!", __func__);
		return NULL;
	}
	int i;
	for (i = 0; i < tg->config->dc_options_len; ++i) {
		tl_dcOption_t *dco = 
			(tl_dcOption_t *)tg->config->dc_options_[i];
		if (!dco)
			continue;
		if (dco->id_ == dc)
			return (const char *)dco->ip_address_.data;	
	}

	ON_ERR(tg, "%s: can't get ip address for dc: %d", 
			__func__, dc);
	return NULL;
}

void tg_rpc_drop_answer(tg_t *tg, uint64_t msg_id)
{
	buf_t drop = tl_rpc_drop_answer(msg_id);
	tg_send_query_sync(tg, &drop);
	buf_free(drop);
}

tl_t *tg_tl_from_gzip(tg_t *tg, tl_t *tl)
{
	if (tl == NULL){
		ON_ERR(tg, "%s: tl is NULL", __func__);
		return NULL;
	}

	if (tl->_id != id_gzip_packed){
		ON_ERR(tg, "%s: is not GZIP", __func__);
		return NULL;
	}

	// handle gzip
	tl_gzip_packed_t *gzip =
		(tl_gzip_packed_t *)tl;

	ON_LOG(tg, "try to gunzip buffer with len: %d", 
			gzip->packed_data_.size);

	buf_t buf;
	int _e = 
		gunzip_buf(&buf, gzip->packed_data_);
	if (_e) {
		char *err = gunzip_buf_err(_e);
		ON_ERR(tg, "%s: %s", __func__, err);
		free(err);
	} else {
		tl_t *tl = tl_deserialize(&buf);
		buf_free(buf);
		return tl;
	}

	return NULL;
}

void tg_new_session(tg_t *tg)
{
	assert(tg);
	int err = pthread_mutex_lock(&tg->queuem);
	if (err){
		ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
		return;
	}

	buf_free(tg->ssid);	
	tg->ssid = buf_rand(8);
	
	pthread_mutex_unlock(&tg->queuem);
}
