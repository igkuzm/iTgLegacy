#include "queue.h"
#include "../mtx/include/api.h"
#include "../mtx/include/buf.h"
#include "../mtx/include/setup.h"
#include "../mtx/include/types.h"
#include "net.h"
#include "transport.h"
#include "../tl/alloc.h"
#include "list.h"
#include "tg.h"
#include "updates.h"
#include <assert.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include "stb_ds.h"
#include "errors.h"
#if INTPTR_MAX == INT32_MAX
    #define THIS_IS_32_BIT_ENVIRONMENT
		#define _LD_ "%lld"
#elif INTPTR_MAX == INT64_MAX
    #define THIS_IS_64_BIT_ENVIRONMENT
		#define _LD_ "%ld"
#else
    #error "Environment not 32 or 64-bit."
#endif

enum RTL{
	RTL_EX, // exit loop
	RTL_ER, // error socket
	RTL_RQ, // read socket again
	RTL_RS, // resend query
};

static int cmp_msgid(void *msgidp, void *itemp)
{
	tg_queue_t *item = itemp;
	uint64_t *msgid = msgidp;
	if (*msgid == item->msgid)
		return 1;
	return 0;
}

static int flood_wait_for_seconds(
		tg_queue_t *queue, int seconds)
{
	ON_ERR(queue->tg, 
					"You are blocked for flooding. Wait %.2d:%.2d:%2d",
					seconds/3600, seconds%3600/60, seconds%3600%60);
					
	// sleep and resend query
	sleep(seconds);

	// resend queue
	tg_queue_new(
			queue->tg, 
			&queue->query, 
			queue->ip,
			queue->port,
			queue->userdata, 
			queue->on_done, 
			queue->progressp, 
			queue->progress);
	
	return 0;
}

static int migrate_to_dc(
		tg_queue_t *queue, const struct dc_t *dc)
{
	ON_LOG(queue->tg, "%s: MIGRATE TO: %d", 
			__func__, dc->number);

	// resend queue
	tg_queue_new(
			queue->tg, 
			&queue->query, 
			dc->ipv4,
			queue->port,
			queue->userdata, 
			queue->on_done, 
			queue->progressp, 
			queue->progress);
	
	return 0;
}

static void catched_tl(tg_t *tg, uint64_t msg_id, tl_t *tl)
{
	assert(tg);
	ON_LOG(tg, "%s", __func__);

	// get queue
	int err = pthread_mutex_lock(&tg->queuem);
	if (err){
		ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
		return;
	}
	
	tg_queue_t *queue = list_cut(
				&tg->queue, 
				&msg_id, 
				cmp_msgid);
		

	if (queue == NULL){
		ON_ERR(tg, "can't find queue for msg_id: "_LD_" with tl: %s"
				, msg_id, tl?TL_NAME_FROM_ID(tl->_id):"NULL");
		pthread_mutex_unlock(&tg->queuem);
		// drop answer
		//tg_add_todrop(tg, msg_id);
		return;
	}

	ON_ERR(tg, "%s: GOT queue for msg_id: "_LD_"!"
				, __func__, msg_id);

	// lock queue
	err = pthread_mutex_lock(&queue->m);
	pthread_mutex_unlock(&tg->queuem); // unlock list
	if (err){
		ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
		return;
	}

	if (tl == NULL){
		ON_ERR(tg, "%s: tl is NULL", __func__);
		if (queue->on_done)
			queue->on_done(queue->userdata, tl);
		pthread_mutex_unlock(&queue->m); // unlock
		return;
	}
		
	ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(tl->_id));

	switch (tl->_id) {
		case id_gzip_packed:
			{
				// handle gzip
				tl_gzip_packed_t *obj =
					(tl_gzip_packed_t *)tl;

				tl_t *ttl = NULL;
				buf_t buf;
				int _e = gunzip_buf(&buf, obj->packed_data_);
				if (_e)
				{
					char *err = gunzip_buf_err(_e);
					ON_ERR(tg, "%s: %s", __func__, err);
					free(err);
				} else {
					ttl = tl_deserialize(&buf);
					buf_free(buf);
				}
		
				if (queue->on_done)
					queue->on_done(queue->userdata, ttl);
				if (ttl)
					tl_free(ttl);

				queue->loop = false; // stop receive data!
				pthread_mutex_unlock(&queue->m); // unlock
				return; // do not run on_done!
			}
			break;
		case id_bad_msg_notification:
			{
				tl_bad_msg_notification_t *obj = 
					(tl_bad_msg_notification_t *)tl;
				// handle bad msg notification
				char *err = tg_strerr(tl);
				ON_ERR(queue->tg, "%s", err);
				free(err);
				tl = NULL;
				// add time diff
				pthread_mutex_lock(&queue->tg->seqnm);
				queue->tg->timediff = ntp_time_diff();
				pthread_mutex_unlock(&queue->tg->seqnm);
			}
			break;
		case id_rpc_error:
			{
				tl_rpc_error_t *rpc_error = 
					(tl_rpc_error_t *)tl;

				// check file/user/phone migrate
				const struct dc_t *dc = 
					tg_error_migrate(tg, RPC_ERROR(tl));
				if (dc){
					ON_LOG(queue->tg, "%s: %s", __func__, RPC_ERROR(tl));
					// check if user/phone migrate
					if (tg_error_file_migrate(tg, RPC_ERROR(tl)) == NULL)
					{
						// change main ip address
						tg_set_server_address(tg, dc->ipv4, tg->port);
						ip_address_to_database(tg, dc->ipv4);
					}
					migrate_to_dc(queue, dc);
					queue->loop = false; // stop receive data!
					pthread_mutex_unlock(&queue->m); // unlock
					return; // do not run on_done!
				}

				// check flood wait
				int wait = tg_error_flood_wait(tg, RPC_ERROR(tl));
				if (wait){
					ON_LOG(queue->tg, "%s: %s", __func__, RPC_ERROR(tl));
					flood_wait_for_seconds(queue, wait);
					queue->loop = false; // stop receive data!
					pthread_mutex_unlock(&queue->m); // unlock
					return; // do not run on_done!
				}
				
				// frint error
				char *err = tg_strerr(tl);
				ON_ERR(queue->tg, "%s: %s", __func__, err);
				free(err);
				break; // run on_done
			}
			break;
		
		default:
			break;
	}

	if (queue->on_done)
		queue->on_done(queue->userdata, tl);
	
	// stop query
	queue->loop = false;

	pthread_mutex_unlock(&queue->m); // unlock
}

static void handle_tl(tg_queue_t *queue, tl_t *tl)
{
	int i;
	if (tl == NULL){
		ON_ERR(queue->tg, "%s: tl is NULL", __func__);
		return;
	}
	ON_LOG(queue->tg, "%s: %s", __func__, 
			TL_NAME_FROM_ID(tl->_id));

	switch (tl->_id) {
		case id_gzip_packed:
			{
				// handle gzip
				tl_gzip_packed_t *obj =
					(tl_gzip_packed_t *)tl;

				buf_t buf;
				int _e = gunzip_buf(&buf, obj->packed_data_);
				if (_e)
				{
					char *err = gunzip_buf_err(_e);
					ON_ERR(queue->tg, "%s: %s", __func__, err);
					free(err);
				}
				tl_t *ttl = tl_deserialize(&buf);
				buf_free(buf);
				handle_tl(queue, ttl);
				if (ttl)
					tl_free(ttl);
			}
			break;
		case id_msg_container:
			{
				tl_msg_container_t *container = 
					(tl_msg_container_t *)tl; 
				/*ON_LOG_BUF(queue->tg, container->_buf, "CONTAINER: ");*/
				ON_LOG(queue->tg, "%s: container %d long", 
						__func__, container->messages_len);
				for (i = 0; i < container->messages_len; ++i) {
					mtp_message_t m = container->messages_[i];
					// add to ack
					tg_add_msgid(queue->tg, m.msg_id);
					
					tl_t *ttl = tl_deserialize(&m.body);
					handle_tl(queue, ttl);
					if (ttl)
						tl_free(ttl);
				}
			}
			break;
		case id_new_session_created:
			{
				tl_new_session_created_t *obj = 
					(tl_new_session_created_t *)tl;
				// handle new session
				ON_LOG(queue->tg, "new session created...");
			}
			break;
		case id_pong:
			{
				tl_pong_t *obj = 
					(tl_pong_t *)tl;
				// handle pong
				ON_LOG(queue->tg, "pong...");
			}
			break;
		case id_bad_msg_notification:
			{
				tl_bad_msg_notification_t *obj = 
					(tl_bad_msg_notification_t *)tl;
				// handle bad msg notification
				char *err = tg_strerr(tl);
				ON_ERR(queue->tg, "%s", err);
				free(err);
				// add time diff
				pthread_mutex_lock(&queue->tg->seqnm);
				queue->tg->timediff = ntp_time_diff();
				pthread_mutex_unlock(&queue->tg->seqnm);
			}
			break;
		case id_rpc_error:
			{
				tl_rpc_error_t *rpc_error = 
					(tl_rpc_error_t *)tl;
				char *err = tg_strerr(tl);
				ON_ERR(queue->tg, "%s: %s", __func__, err);
				free(err);
			}
			break;
		case id_msgs_ack:
			{
				tl_msgs_ack_t *msgs_ack = 
					(tl_msgs_ack_t *)tl;
				/*ON_LOG_BUF(queue->tg, tl->_buf, "GOT ACK:");*/
			}
			break;
		case id_msg_detailed_info:
			{
				tl_msg_detailed_info_t *di = 
					(tl_msg_detailed_info_t *)tl;
				catched_tl(queue->tg, di->answer_msg_id_, NULL);
			}
			break;
		case id_msg_new_detailed_info:
			{
				tl_msg_new_detailed_info_t *di = 
					(tl_msg_new_detailed_info_t *)tl;
				catched_tl(queue->tg, di->answer_msg_id_, NULL);
			}
			break;
		case id_rpc_result:
			{
				tl_rpc_result_t *rpc_result = 
					(tl_rpc_result_t *)tl;
				if (rpc_result->result_)
					ON_ERR(queue->tg, "got msg result: (%s) for msg_id: "_LD_"",
							TL_NAME_FROM_ID(rpc_result->result_->_id), 
							rpc_result->req_msg_id_);
				catched_tl(queue->tg, rpc_result->req_msg_id_, rpc_result->result_);
			}
			break;
		case id_updatesTooLong: case id_updateShort:
		case id_updateShortMessage: case id_updateShortChatMessage:
		case id_updateShortSentMessage: case id_updatesCombined:
		case id_updates:
			{
				// do updates
				tg_do_updates(queue->tg, tl);
			}
			break;;

		default:
			break;
	}
}

static enum RTL _tg_receive(tg_queue_t *queue, int sockfd)
{
	ON_LOG(queue->tg, "%s", __func__);
	buf_t r = buf_new();
	// get length of the package
	uint32_t len;
	int s = recv(sockfd, &len, 4, 0);
	if (s<0){
		ON_ERR(queue->tg, "%s: %d: socket error: %d", 
				__func__, __LINE__, s);
		buf_free(r);
		return RTL_ER;
	}

	ON_LOG(queue->tg, "%s: prepare to receive len: %d", __func__, len);
	if (len < 0) {
		// this is error - report it
		ON_ERR(queue->tg, "%s: received wrong length: %d", __func__, len);
		buf_free(r);
		return RTL_EX;
	}

	// realloc buf to be enough size
	if (buf_realloc(&r, len)){
		// handle error
		ON_ERR(queue->tg, "%s: error buf realloc to size: %d", __func__, len);
		buf_free(r);
		return RTL_EX;
	}

	// get data
	uint32_t received = 0; 
	while (received < len){
		int s = recv(
				sockfd, 
				&r.data[received], 
				len - received, 
				0);	
		if (s<0){
			ON_ERR(queue->tg, "%s: %d: socket error: %d", 
					__func__, __LINE__, s);
			buf_free(r);
			return RTL_ER;
		}
		received += s;
		
		ON_LOG(queue->tg, 
				"%s: expected: %d, received: %d, total: %d (%d%%)", 
				__func__, len, s, received, received*100/len);

		if (queue->progress){
			if(queue->progress(queue->progressp, received, len)){
				buf_free(r);
				ON_LOG(queue->tg, "%s: download canceled", __func__);
				// drop
				tg_add_todrop(queue->tg, queue->msgid);
				return RTL_EX;
			}
		}
	}

	// get payload 
	r.size = len;
	if (r.size == 4 && buf_get_ui32(r) == 0xfffffe6c){
		buf_free(r);
		ON_ERR(queue->tg, "%s: 404 ERROR", __func__);
		return RTL_EX;
	}

	// decrypt
	buf_t d = tg_decrypt(queue->tg, r, true);
	if (!d.size){
		buf_free(r);
		return RTL_EX;
	}
	buf_free(r);

	// deheader
	buf_t msg = tg_deheader(queue->tg, d, true);
	buf_free(d);

	// deserialize 
	tl_t *tl = tl_deserialize(&msg);
	buf_free(msg);

	// check server salt
	if (tl->_id == id_bad_server_salt){
		ON_LOG(queue->tg, "BAD SERVER SALT: resend query");
		// resend query
		return RTL_RS;
	}

	// handle tl
	handle_tl(queue, tl);
	if (tl)
		tl_free(tl);
	
	return RTL_RQ; // read socket again
}

static void tg_send_ack(void *data)
{
	tg_queue_t *queue = data;
	ON_LOG(queue->tg, "%s", __func__);
	
	// send ACK
	buf_t ack = tg_ack(queue->tg);	
	if (ack.size < 1){
		buf_free(ack);
		return;
	}
	buf_t query = tg_prepare_query(
			queue->tg, &ack, true, NULL);
	buf_free(ack);

	int s = 
		send(queue->socket, query.data, query.size, 0);
	buf_free(query);
	
	if (s < 0){
		ON_ERR(queue->tg, "%s: socket error", __func__);
		pthread_mutex_unlock(&queue->tg->msgidsm);
		return;
	}
}

static int tg_send(void *data)
{
	int err = 0;
	// send query
	tg_queue_t *queue = data;
	ON_LOG(queue->tg, "%s", __func__);
	// auth_key
	if (!queue->tg->key.size){
		err = pthread_mutex_lock(&queue->tg->queuem);
		if (err){
			ON_ERR(queue->tg, "%s: can't lock mutex: %d", __func__, err);
			return 1;
		}
		close(queue->socket);
		api.app.open(queue->tg->ip, queue->tg->port);	
		queue->tg->key = 
			buf_add(shared_rc.key.data, shared_rc.key.size);
		queue->tg->salt = 
			buf_add(shared_rc.salt.data, shared_rc.salt.size);
		queue->socket = shared_rc.net.sockfd;
		queue->tg->seqn = shared_rc.seqnh + 1;
		pthread_mutex_unlock(&queue->tg->queuem);
	}

	// session id
	if (!queue->tg->ssid.size){
		err = pthread_mutex_lock(&queue->tg->queuem);
		if (err){
			ON_ERR(queue->tg, "%s: can't lock mutex: %d", __func__, err);
			return 1;
		}
		queue->tg->ssid = buf_rand(8);
		pthread_mutex_unlock(&queue->tg->queuem);
	}

	// server salt
	if (!queue->tg->salt.size){
		err = pthread_mutex_lock(&queue->tg->queuem);
		if (err){
			ON_ERR(queue->tg, "%s: can't lock mutex: %d", __func__, err);
			return 1;
		}
		queue->tg->salt = buf_rand(8);
		pthread_mutex_unlock(&queue->tg->queuem);
	}

	// prepare query
	buf_t b = tg_prepare_query(
			queue->tg, 
			&queue->query, 
			true, 
			&queue->msgid);
	if (!b.size)
	{
		ON_ERR(queue->tg, "%s: can't prepare query", __func__);
		buf_free(b);
		tg_net_close(queue->tg, queue->socket);
		return 1;
	}

	// send query
	int s = 
		send(queue->socket, b.data, b.size, 0);
	if (s < 0){
		ON_ERR(queue->tg, "%s: socket error: %d", __func__, s);
		buf_free(b);
		tg_net_close(queue->tg, queue->socket);
		return 1;
	}
		
	/*tg_net_close(queue->tg, queue->socket);*/
	return 0;
}

static void * tg_run_queue(void * data)
{
	tg_queue_t *queue = data;
	ON_LOG(queue->tg, "%s", __func__);
	// open socket
	queue->socket = 
		tg_net_open(queue->tg, queue->ip, queue->port);
	if (queue->socket < 0)
	{
		ON_ERR(queue->tg, "%s: can't open socket", __func__);
		buf_free(queue->query);
		free(queue);
		pthread_exit(NULL);	
	}

	// add to list
	int err = 0;
	err = pthread_mutex_lock(&queue->tg->queuem);
	if (err){
		ON_ERR(queue->tg, "%s: can't lock mutex: %d", __func__, err);
		buf_free(queue->query);
		free(queue);
		pthread_exit(NULL);	
	}
	list_add(&queue->tg->queue, data);
	pthread_mutex_unlock(&queue->tg->queuem);

	// send ack - use container method in header.c
	//tg_send_ack(data);
	
	// send
	if (tg_send(data))
		queue->loop = false;

	// receive loop
	enum RTL res; 
	while (queue->loop) {
		// check opened sockets for not files download
		if (queue->fileDownload){
			res = _tg_receive(queue, queue->socket);
			if (res == RTL_RS)
			{	
				if (tg_send(data))
					continue;
				else 
					break;
			}

			if (res == RTL_EX || res == RTL_ER)
				break;

			continue;
		}

		if (pthread_mutex_trylock(&queue->tg->socket_mutex))
		{
			// receive
			/*ON_LOG(queue->tg, "%s: receive...", __func__);*/
			//usleep(1000); // in microseconds
			res = _tg_receive(queue, queue->socket);
			tg_mutex_unlock(&queue->tg->socket_mutex);
			if (res == RTL_RS)
			{	
				if (tg_send(data))
					continue;
				else
				 break;
			}

			if (res == RTL_EX || res == RTL_ER)
				break;

		} else // pthread_mutex_trylock
			continue;
	}
	// close socket
	if (queue->socket >= 0)
		tg_net_close(queue->tg, queue->socket);

	// remove fromqueue
	tg_t *tg = queue->tg;
	tg_mutex_lock(tg, &tg->queuem,
		ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
		pthread_exit(NULL);
	);	
	list_cut(&tg->queue, &queue->msgid, cmp_msgid);
		
	/*buf_free(queue->query);*/
	free(queue);
	pthread_mutex_unlock(&tg->queuem);
	pthread_exit(NULL);	
}

static void * tg_run_timer(void * data)
{
	tg_queue_t *queue = data;
	ON_LOG(queue->tg, "%s", __func__);
	//usleep(1000); // in microseconds
	sleep(2);
	queue->loop = false;
	pthread_exit(NULL);	
}

tg_queue_t * tg_queue_new(
		tg_t *tg, buf_t *query, 
		const char *ip, int port,
		void *userdata, void (*on_done)(void *userdata, const tl_t *tl),
		void *progressp, 
		int (*progress)(void *progressp, int size, int total))
{
	ON_LOG(tg, "%s", __func__);
	tg_queue_t *queue = NEW(tg_queue_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__);
			return NULL;);

	if (pthread_mutex_init(&queue->m, NULL)){
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}

	queue->tg = tg;
	queue->loop = true;
	queue->query = buf_add_buf(*query);
	strncpy(queue->ip, ip, sizeof(queue->ip)-1);
	queue->port = port;
	queue->userdata = userdata;
	queue->on_done = on_done;
	queue->progressp = progressp;
	queue->progress = progress;

	// start thread
	if (pthread_create(
			&(queue->p), 
			NULL, 
			tg_run_queue, 
			queue))
	{
		ON_ERR(tg, "%s: can't create thread", __func__);
		return NULL;
	}

	// start timer
	//pthread_create(
			//&(queue->p), 
			//NULL, 
			//tg_run_timer, 
			//queue);

	return queue;
}

pthread_t tg_send_query_async_with_progress(tg_t *tg, buf_t *query,
		void *userdata, void (*callback)(void *userdata, const tl_t *tl),
		void *progressp, 
		int (*progress)(void *progressp, int size, int total))
{
	ON_LOG(tg, "%s: tg: %p, query: %p, userdata: %p, callback: %p"
			       "progressp: %p, progress: %p",
		 	__func__, tg, query, userdata, callback, progressp, progress);
	tg_queue_t *queue = 
		tg_queue_new(tg, query, 
				tg->ip, tg->port,
				userdata, callback,
			 	progressp, progress);
	return queue->p;
}

pthread_t tg_send_query_async(tg_t *tg, buf_t *query,
		void *userdata, void (*callback)(void *userdata, const tl_t *tl))
{
	ON_LOG(tg, "%s: tg: %p, query: %p, userdata: %p, callback: %p",
		 	__func__, tg, query, userdata, callback);
	return tg_send_query_async_with_progress(
			tg, query, 
			userdata, callback,
			NULL, NULL);
}

static void tg_send_query_sync_cb(void *d, const tl_t *tl)
{
	fprintf(stderr, "%s\n", __func__);
	tl_t **tlp = d;
	*tlp = tl_deserialize((buf_t *)(&tl->_buf));
}

tl_t *tg_send_query_sync_with_progress(tg_t *tg, buf_t *query,
		void *progressp, 
		int (*progress)(void *progressp, int size, int total))
{
	tl_t *tl = NULL;
	pthread_t p = 
		tg_send_query_async_with_progress(tg, query, 
				&tl, tg_send_query_sync_cb, 
				progressp, progress);
	
	pthread_join(p, NULL);

	ON_LOG(tg, "%s got tl: %s"
			, __func__, tl?TL_NAME_FROM_ID(tl->_id):"NULL");

	return tl;
}

tl_t *tg_send_query_sync(tg_t *tg, buf_t *query)
{
	tl_t *tl = NULL;
	pthread_t p = 
		tg_send_query_async(tg, query, 
				&tl, tg_send_query_sync_cb);
	
	pthread_join(p, NULL);

	ON_LOG(tg, "%s got tl: %s"
			, __func__, tl?TL_NAME_FROM_ID(tl->_id):"NULL");

	return tl;
}

void tg_queue_cancell_all(tg_t *tg)
{
	ON_LOG(tg, "%s", __func__);
	int err = pthread_mutex_lock(&tg->queuem);
	if (err){
		ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
		return;
	}
	tg_queue_t *queue;
	list_for_each(tg->queue, queue)
	{
		// lock queue - (it may be locked by catche_tl)
		if (pthread_mutex_trylock(&queue->m) == 0){
			queue->loop = false;
			pthread_mutex_unlock(&queue->m);
		}
	}

	list_free(&tg->queue);
	pthread_mutex_unlock(&tg->queuem);
}

int tg_queue_cancell_queue(tg_t *tg, uint64_t msg_id){

	int err = pthread_mutex_lock(&tg->queuem);
	if (err){
		ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
		return 1;
	}
	
	tg_queue_t *queue = list_cut(
				&tg->queue, 
				&msg_id, 
				cmp_msgid);
		

	if (queue == NULL){
		ON_ERR(tg, "%s: can't find queue for msg_id: "_LD_""
				, __func__, msg_id);
		pthread_mutex_unlock(&tg->queuem);
		return 1;
	}

	// lock queue
	err = pthread_mutex_lock(&queue->m);
	pthread_mutex_unlock(&tg->queuem); // unlock list
	if (err){
		ON_ERR(tg, "%s: can't lock mutex: %d", __func__, err);
		return 1;
	}
	
	// stop query
	queue->loop = false;
	pthread_mutex_unlock(&queue->m); // unlock
	
	return 0;
}

tl_t *tg_send_query(tg_t *tg, buf_t *query){
	return tg_send_query_sync(tg, query);
}
