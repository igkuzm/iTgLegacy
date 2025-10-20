/**
 * File              : send_query.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 03.02.2025
 * Last Modified Date: 09.02.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include <pthread.h>
#include <sys/select.h>
#if INTPTR_MAX == INT32_MAX
    #define THIS_IS_32_BIT_ENVIRONMENT
		#define _LD_ "%lld"
#elif INTPTR_MAX == INT64_MAX
    #define THIS_IS_64_BIT_ENVIRONMENT
		#define _LD_ "%ld"
#else
    #error "Environment not 32 or 64-bit."
#endif


#include "tg.h"
#include "net.h"
#include "transport.h"
#include "updates.h"
#include "../mtx/include/api.h"
#include <assert.h>
#include <stdint.h>
#include <sys/socket.h>
#include "answer.h"

// return msg_id or 0 on error
static uint64_t tg_send(tg_t *tg, buf_t *query, int *socket)
{
	assert(tg && query);
	int err = 0;
	
	// send query
	ON_LOG(tg, "%s: query: %s, socket: %d", 
			__func__, TL_NAME_FROM_ID(buf_get_ui32(*query)), *socket);

	// auth_key
	if (!tg->key.size){
		ON_LOG(tg, "new auth key");
		tg_net_close(tg, *socket);
		api.app.open(tg->ip, 80); // set port	
		tg->key = 
			buf_add(shared_rc.key.data, shared_rc.key.size);
		tg->salt = 
			buf_add(shared_rc.salt.data, shared_rc.salt.size);
		*socket = shared_rc.net.sockfd;
		tg->seqn = shared_rc.seqnh + 1;
	}

	// session id
	if (!tg->ssid.size){
		ON_LOG(tg, "new session id");
		tg->ssid = buf_rand(8);
	}

	// server salt
	if (!tg->salt.size){
		ON_LOG(tg, "new server salt");
		tg->salt = buf_rand(8);
	}

	// prepare query
	uint64_t msg_id = 0;
	buf_t b = tg_prepare_query(
			tg, 
			query, 
			true, 
			&msg_id);
	if (!b.size)
	{
		ON_ERR(tg, "%s: can't prepare query", __func__);
		buf_free(b);
		tg_net_close(tg, *socket);
		return 0;
	}

	// send query
	int s = 
		send(*socket, b.data, b.size, 0);
	if (s < 0){
		ON_ERR(tg, "%s: socket error: %d", __func__, s);
		buf_free(b);
		return 0;
	}

	return msg_id;
}

static int tg_receive(tg_t *tg, int *sockfd, fd_set *fdset, buf_t *msg,
		void *progressp, 
		void (*progress)(void *progressp, int size, int total))
{
	assert(tg);
	ON_LOG(tg, "%s: socket: %d", __func__, *sockfd);
	
	// get length of the package
	uint32_t len;
	if (!FD_ISSET(*sockfd, fdset)){
		ON_ERR(tg, "%s: socket is closed!", __func__);
		return 1;
	}
	int s = recv(*sockfd, &len, 4, 0);
	if (s<0){
		ON_ERR(tg, "%s: %d: socket error: %d"
				, __func__, __LINE__, s);
		return 1;
	}

	ON_LOG(tg, "%s: prepare to receive len: %d", __func__, len);
	if (len < 0) {
		// this is error - report it
		ON_ERR(tg, "%s: received wrong length: %d", __func__, len);
		return 1;
	}

	// realloc buf to be enough size
	buf_t buf = buf_new();
	if (buf_realloc(&buf, len)){
		// handle error
		ON_ERR(tg, "%s: error buf realloc to size: %d", __func__, len);
		return 1;
	}

	// get data
	uint32_t received = 0; 
	while (received < len){
		int s = recv(
				*sockfd, 
				&buf.data[received], 
				len - received, 
				0);	
		if (s<0){
			ON_ERR(tg, "%s: %d: socket error: %d"
					, __func__, __LINE__, s);
			buf_free(buf);
			return 1;
		}
		received += s;
		
		ON_LOG(tg, "%s: expected: %d, received: %d, total: %d (%d%%)", 
				__func__, len, s, received, received*100/len);

		if (progress)
			progress(progressp, received, len);
	}

	// get payload 
	buf.size = len;
	if (buf.size == 4 && buf_get_ui32(buf) == 0xfffffe6c){
		ON_ERR(tg, "%s: 404 ERROR", __func__);
		buf_free(buf);
		return 1;
	}

	// decrypt
	buf_t d = tg_decrypt(tg, buf, true);
	buf_free(buf);
	if (!d.size){
		return 1;
	}

	// deheader
	*msg = tg_deheader(tg, d, true);
	buf_free(d);

	return 0;
}

static int tg_parse_answer_callback(void *d, const tl_t *tl)
{
	tl_t **answer = d;
	*answer = tl_deserialize((buf_t *)(&tl->_buf));
	return 0;
}

tl_t *tg_send_query_via_with_progress(tg_t *tg, buf_t *query,
		const char *ip, int port,
		void *progressp, 
		void (*progress)(void *progressp, int size, int total))
{
	assert(tg && query && ip);
	ON_LOG(tg, "%s: %s: %d", __func__, ip, port);

	fd_set fdset;
	FD_ZERO(&fdset);
	
	// open socket
	//int socket = tg_net_open(tg, ip, port);
	int socket = tg_net_open(tg, ip, 80);
	if (socket < 0)
	{
		ON_ERR(tg, "%s: can't open socket", __func__);
		return NULL;
	}
	FD_SET(socket, &fdset);

	// lock mutex
	ON_LOG(tg, "%s: try to lock mutex...", __func__);
	if (pthread_mutex_lock(&tg->send_query))
	{
		ON_ERR(tg, "%s: can't lock mutex", __func__);
		return NULL;
	}
	ON_LOG(tg, "%s: %s: %d: catched mutex!", __func__, ip, port);
	
	// send query
	uint64_t msg_id = tg_send(tg, query, &socket);
	if (msg_id == 0){
		pthread_mutex_unlock(&tg->send_query);
		return NULL;
	}

recevive_data:;
	// reseive
	buf_t r;
	if (tg_receive(tg, &socket, &fdset, &r, progressp, progress))
	{
		pthread_mutex_unlock(&tg->send_query);
		return NULL;
	}

	// deserialize 
	tl_t *tl = tl_deserialize(&r);
	buf_free(r);

	tl_t *answer = NULL;
	tg_parse_answer(tg, tl, msg_id,
		 	&answer, tg_parse_answer_callback);
	if (answer){
		tl_free(tl);
		tl = answer;
	}
	
	if (tl == NULL){
		pthread_mutex_unlock(&tg->send_query);
		return NULL;
	}

	// check gzip
	if (tl->_id == id_gzip_packed){
		ON_LOG(tg, "%s: got GZIP", __func__);
		tl = tg_tl_from_gzip(tg, tl);
	}

	// check server salt
	if (tl->_id == id_bad_server_salt){
		ON_LOG(tg, "BAD SERVER SALT: resend query");
		// free tl
		tl_free(tl);
		// resend query
		tg_net_close(tg, socket);
		pthread_mutex_unlock(&tg->send_query);
		return tg_send_query_via_with_progress(
				tg, query, ip, port, progressp, progress);
	}
				
	// check ack
	if (tl->_id == id_msgs_ack){
		ON_LOG(tg, "%s: got ACK - receive data again", __func__);
		tl_free(tl);
		goto recevive_data;
	}

	// check detailed info
	//if (tl->_id == id_msg_detailed_info ||
			//tl->_id == id_msg_new_detailed_info)
	//{
		//tl_free(tl);
		//pthread_mutex_unlock(&tg->send_query);
		//return NULL;
	//}
	
	// check other
	switch (tl->_id) {
		case id_updatesTooLong: case id_updateShort:
		case id_updateShortMessage: case id_updateShortChatMessage:
		case id_updateShortSentMessage: case id_updatesCombined:
		case id_updates:
			// get data again
			tl_free(tl);
			goto recevive_data;
			break;
			
		default:
			break;
	}

	pthread_mutex_unlock(&tg->send_query);
	return tl;
}

tl_t *tg_send_query_via(tg_t *tg, buf_t *query,
		const char *ip, int port)
{
	return tg_send_query_via_with_progress(
			tg, query, ip, port, 
			NULL, NULL);
}

tl_t *tg_send_query_with_progress(tg_t *tg, buf_t *query,
		void *progressp, 
		void (*progress)(void *progressp, int size, int total))
{
	return tg_send_query_via_with_progress(
			tg, query, tg->ip, tg->port, 
			progressp, progress);
}

tl_t *tg_send_query(tg_t *tg, buf_t *query)
{
	return tg_send_query_via_with_progress(
			tg, query, tg->ip, tg->port, 
			NULL, NULL);
}

//tl_t *tg_send_query_sync(tg_t *tg, buf_t *query){
	//return tg_send_query(tg, query);
//}
