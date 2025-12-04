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
	RTL_EXIT,   // exit loop
	RTL_ERROR,  // error
	RTL_REREAD, // read socket again
	RTL_RESEND, // resend query
};

static int cmp_msgid(void *msgidp, void *itemp)
{
	tg_queue_t *item = itemp;
	uint64_t *msgid = msgidp;
	if (*msgid == item->msgid)
		return 1;
	return 0;
}

static tg_queue_t * tg_queue_cut(tg_t *tg, uint64_t msg_id)
{
	tg_queue_t *queue = NULL;
	assert(tg);

	tg_mutex_lock(tg, &tg->queue_lock, 
			ON_ERR(tg, "%s: can't lock queue list", __func__);
			return queue);
	queue = list_cut(
				&tg->queue, 
				&msg_id, 
				cmp_msgid);
	tg_mutex_unlock(&tg->queue_lock);
	return queue;	
}

static void tg_queue_add(tg_t *tg, tg_queue_t * queue)
{
	assert(tg);
	assert(queue);

	tg_mutex_lock(tg, &tg->queue_lock, 
			ON_ERR(tg, "%s: can't lock queue list", __func__);
			return);
	list_add(&tg->queue, queue);
	tg_mutex_unlock(&tg->queue_lock);
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
			queue->multithread,
			queue->userdata, 
			queue->on_done, 
			queue->progressp, 
			queue->progress);
	
	return 0;
}

static int migrate_to_dc(
		tg_queue_t *queue, const struct dc_t *dc, tl_t *tl)
{
	ON_ERR(queue->tg, "%s: MIGRATE TO: %d", 
			__func__, dc->number);
	// get ip
	const char *ip = 
		tg_ip_address_for_dc(queue->tg, dc->number);
	if (ip == NULL){
		ON_ERR(queue->tg, "%s: can't get ip from config", __func__);
		ip = dc->ipv4;
	}

	// check if user/phone migrate
	if (tg_error_file_migrate(queue->tg, RPC_ERROR(tl)) == NULL)
	{
		// change main ip address
		tg_set_server_address(queue->tg, ip, queue->tg->port);
		ip_address_to_database(queue->tg, ip);
	}

	// resend queue
	tg_queue_new(
			queue->tg, 
			&queue->query, 
			ip,
			queue->port,
			queue->multithread,
			queue->userdata, 
			queue->on_done, 
			queue->progressp, 
			queue->progress);
	
	return 0;
}

static void catched_tl(tg_t *tg, uint64_t msg_id, tl_t *tl)
{
	tg_queue_t *queue = NULL;

	assert(tg);
	ON_LOG(tg, "%s", __func__);

	// get queue
	queue = tg_queue_cut(tg, msg_id);
	if (queue == NULL){
		ON_ERR(tg, "can't find queue for msg_id: "_LD_" with tl: %s"
				, msg_id, tl?TL_NAME_FROM_ID(tl->_id):"NULL");
		// drop answer
		//tg_add_todrop(tg, msg_id);
		return;
	}

	ON_ERR(tg, "%s: GOT queue for msg_id: "_LD_"!"
				, __func__, msg_id);

	// check if in loop
	if (!queue->loop)
		return;

	// lock queue
	tg_mutex_lock(tg, &queue->lock, 
			ON_LOG(tg, "%s: can't lock queue", __func__);
			return);

	if (tl == NULL){
		ON_ERR(tg, "%s: tl is NULL", __func__);
		if (queue->on_done)
			queue->on_done(queue->userdata, tl);
		tg_mutex_unlock(&queue->lock); // unlock
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
				tg_mutex_unlock(&queue->lock); // unlock
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
				tg_mutex_lock(tg, &queue->tg->seqnm, break);
				queue->tg->timediff = ntp_time_diff();
			  tg_mutex_unlock(&queue->tg->seqnm);
			}
			break;
		case id_rpc_error:
			{
				tl_rpc_error_t *rpc_error = 
					(tl_rpc_error_t *)tl;

				ON_ERR(tg, "RPC_ERROR: %s for msgid: "_LD_"",
						RPC_ERROR(tl), msg_id);

				// check file/user/phone migrate
				const struct dc_t *dc = 
					tg_error_migrate(tg, RPC_ERROR(tl));
				if (dc){
					ON_LOG(queue->tg, "%s: %s", __func__, RPC_ERROR(tl));
					migrate_to_dc(queue, dc, tl);
					queue->loop = false; // stop receive data!
					tg_mutex_unlock(&queue->lock); // unlock
					return; // do not run on_done!
				}

				// check flood wait
				int wait = tg_error_flood_wait(tg, RPC_ERROR(tl));
				if (wait){
					ON_LOG(queue->tg, "%s: %s", __func__, RPC_ERROR(tl));
					flood_wait_for_seconds(queue, wait);
					queue->loop = false; // stop receive data!
					tg_mutex_unlock(&queue->lock); // unlock
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

	tg_mutex_unlock(&queue->lock); // unlock
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
				tg_mutex_lock(queue->tg, &queue->tg->seqnm, break);
				queue->tg->timediff = ntp_time_diff();
				tg_mutex_unlock(&queue->tg->seqnm);
			}
			break;
		case id_rpc_error:
			{
				// check file/user/phone migrate
				const struct dc_t *dc = 
					tg_error_migrate(queue->tg, RPC_ERROR(tl));
				if (dc){
					ON_LOG(queue->tg, "%s: %s", __func__, RPC_ERROR(tl));
					// check if user/phone migrate
					migrate_to_dc(queue, dc, tl);
					queue->loop = false; // stop receive data!
					break;
				}

				// check flood wait
				int wait = tg_error_flood_wait(queue->tg, RPC_ERROR(tl));
				if (wait){
					ON_LOG(queue->tg, "%s: %s", __func__, RPC_ERROR(tl));
					flood_wait_for_seconds(queue, wait);
					queue->loop = false; // stop receive data!
					break;
				}

				// print error
				ON_ERR(queue->tg, "%s: %s", __func__, RPC_ERROR(tl));
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
		return RTL_ERROR;
	}

	ON_LOG(queue->tg, "%s: prepare to receive len: %d", __func__, len);
	if (len < 0) {
		// this is error - report it
		ON_ERR(queue->tg, "%s: received wrong length: %d", __func__, len);
		buf_free(r);
		return RTL_ERROR;
	}

	// realloc buf to be enough size
	if (buf_realloc(&r, len)){
		// handle error
		ON_ERR(queue->tg, "%s: error buf realloc to size: %d", __func__, len);
		buf_free(r);
		return RTL_ERROR;
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
			return RTL_ERROR;
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
				return RTL_EXIT;
			}
		}
	}

	// get payload 
	r.size = len;
	if (r.size == 4 && buf_get_ui32(r) == 0xfffffe6c){
		buf_free(r);
		ON_ERR(queue->tg, "%s: 404 ERROR", __func__);
		return RTL_ERROR;
	}

	// decrypt
	buf_t d = tg_decrypt(queue->tg, r, true);
	if (!d.size){
		buf_free(r);
		return RTL_ERROR;
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
		return RTL_RESEND;
	}

	// handle tl
	handle_tl(queue, tl);
	if (tl)
		tl_free(tl);
	
	return RTL_REREAD; // read again
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

static void tg_prepare_mtproto(tg_queue_t *queue)
{
	tg_t *tg = queue->tg;
	if (!tg->key.size){
		app_t app = api.app.open(queue->tg->ip, queue->tg->port);	
		tg->key = 
			buf_add(shared_rc.key.data, shared_rc.key.size);
		tg->salt = 
			buf_add(shared_rc.salt.data, shared_rc.salt.size);
		queue->socket = shared_rc.net.sockfd;
		tg->seqn = shared_rc.seqnh + 1;	
	}

	if (!tg->ssid.size)
		tg->ssid = buf_rand(8);

	if (!queue->tg->salt.size)
		tg->salt = buf_rand(8);
}

static int tg_send(void *data)
{
	// send query
	tg_queue_t *queue = data;
	tg_t *tg = queue->tg;
	ON_LOG(queue->tg, "%s", __func__);
		
	// prepare protocol
	tg_mutex_lock(tg, &tg->queue_lock,
		ON_ERR(tg, "%s: can't lock mutex", __func__);
		return 1);
	tg_prepare_mtproto(queue);
	tg_mutex_unlock(&tg->queue_lock);
	
	// prepare query
	buf_t b = tg_prepare_query(
			tg, 
			&queue->query, 
			true, 
			&queue->msgid);
	if (!b.size)
	{
		buf_free(b);
		tg_net_close(tg, queue->socket);
		return 1;
	}

	// log
	/*ON_LOG(queue->tg, "%s: %s, msgid: "_LD_"", */
	ON_ERR(tg, "%s: %s, msgid: "_LD_"", 
			__func__, 
			TL_NAME_FROM_ID(buf_get_ui32(queue->query)), 
			queue->msgid);
		
	// send query
	int s = 
		send(queue->socket, b.data, b.size, 0);
	if (s < 0){
		ON_ERR(tg, "%s: socket error: %d", __func__, s);
		buf_free(b);
		tg_net_close(tg, queue->socket);
		return 1;
	}
	
	buf_free(b);
	return 0;
}

static void tg_queue_free(tg_queue_t *queue)
{
	/* TODO:  <03-12-25, yourname> */
	// check of free works
	buf_free(queue->query);
	free(queue);
}

static void *tg_run_queue_exit(tg_queue_t *queue, void *ret)
{
	tg_mutex_unlock(&queue->inloop_lock);
	return ret;
}

static void * tg_run_queue(void * data)
{
	tg_queue_t *queue = data;
	tg_t *tg = queue->tg;

	// lock queue
	tg_mutex_lock(tg, &queue->inloop_lock, 
			ON_ERR(tg, "%s: can't lock queue loop", __func__);
			return NULL);
	
	ON_LOG(tg, "%s", __func__);
	// open socket
	queue->socket = 
		tg_net_open(tg, queue->ip, queue->port);
	if (queue->socket < 0)
	{
		ON_ERR(tg, "%s: can't open socket", __func__);
		return tg_run_queue_exit(queue, NULL);
	}

	// add to list
	tg_queue_add(tg, queue);

	// send ack - use container method in header.c
	//tg_send_ack(data);
	
	// send
	if (tg_send(data))
		queue->loop = false;

	// receive loop
	enum RTL res; 
	while (queue->loop) {
		res = _tg_receive(queue, queue->socket);
		//if (res == RTL_RESEND)
		//{	
			//if (tg_send(data) == 0)
				//continue;
			//break;
		//}

		//if (res == RTL_EXIT || res == RTL_ERROR)
			//break;

		if (queue->multithread){
			res = _tg_receive(queue, queue->socket);
			if (res == RTL_RESEND)
			{	
				if (tg_send(data) == 0)
					continue;
				else 
					break;
			}

			if (res == RTL_EXIT || res == RTL_ERROR)
				break;

			continue;
		}

		if (pthread_mutex_trylock(&tg->socket_mutex))
		{
			// receive
			//ON_LOG(queue->tg, "%s: receive...", __func__);
			//usleep(1000); // in microseconds
			res = _tg_receive(queue, queue->socket);
			tg_mutex_unlock(&tg->socket_mutex);
			if (res == RTL_RESEND)
			{	
				if (tg_send(data) == 0)
					continue;
				else
				 break;
			}

			if (res == RTL_EXIT || res == RTL_ERROR)
				break;

		} else // pthread_mutex_trylock
			continue;
	}

	// close socket
	if (queue->socket >= 0)
		tg_net_close(tg, queue->socket);

	// remove from queue list
	tg_queue_cut(tg, queue->msgid);

	return tg_run_queue_exit(queue, NULL);
}

static void * tg_run_timer(void * data)
{
	// stop queue and free memory
	tg_queue_t *queue = data;
	tg_t *tg = queue->tg;

	//usleep(1000); // in microseconds
	sleep(2);
	ON_LOG(tg, "%s: stop queue", __func__);
	
	queue->loop = false;
	
	// wait to stop
	tg_mutex_lock(tg, &queue->inloop_lock, 
			ON_ERR(tg, "%s: can't lock queue loop", __func__);
			return NULL);
	
	// free queue
	tg_queue_free(queue);
	pthread_exit(NULL);	
}

tg_queue_t * tg_queue_new(
		tg_t *tg, buf_t *query, 
		const char *ip, int port, bool multithread,
		void *userdata, void (*on_done)(void *userdata, const tl_t *tl),
		void *progressp, 
		int (*progress)(void *progressp, int size, int total))
{
	ON_LOG(tg, "%s", __func__);
	tg_queue_t *queue = NEW(tg_queue_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__);
			return NULL;);

	if (pthread_mutex_init(&queue->inloop_lock, NULL)){
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}
	if (pthread_mutex_init(&queue->lock, NULL)){
		ON_ERR(tg, "%s: can't init mutex", __func__);
		return NULL;
	}

	queue->tg = tg;
	queue->loop = true;
	queue->query = buf_add_buf(*query);
	strncpy(queue->ip, ip, sizeof(queue->ip)-1);
	queue->port = port;
	queue->multithread = multithread,
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
	pthread_create(
			&(queue->p), 
			NULL, 
			tg_run_timer, 
			queue);

	return queue;
}

pthread_t tg_send_query_async_with_progress(
		tg_t *tg, buf_t *query, bool multithread,
		void *userdata, void (*callback)(void *userdata, const tl_t *tl),
		void *progressp, 
		int (*progress)(void *progressp, int size, int total))
{
	ON_LOG(tg, "%s: tg: %p, query: %p, userdata: %p, callback: %p"
			       "progressp: %p, progress: %p",
		 	__func__, tg, query, userdata, callback, progressp, progress);
	tg_queue_t *queue = 
		tg_queue_new(tg, query, 
				tg->ip, tg->port, multithread,
				userdata, callback,
			 	progressp, progress);
	return queue->p;
}

pthread_t tg_send_query_async(
		tg_t *tg, buf_t *query, bool multithread,
		void *userdata, void (*callback)(void *userdata, const tl_t *tl))
{
	ON_LOG(tg, "%s: tg: %p, query: %p, userdata: %p, callback: %p",
		 	__func__, tg, query, userdata, callback);
	return tg_send_query_async_with_progress(
			tg, query, multithread, 
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
		tg_send_query_async_with_progress(tg, query, false, 
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
		tg_send_query_async(tg, query, false, 
				&tl, tg_send_query_sync_cb);
	
	pthread_join(p, NULL);

	ON_LOG(tg, "%s got tl: %s"
			, __func__, tl?TL_NAME_FROM_ID(tl->_id):"NULL");

	return tl;
}

void tg_queue_cancell_all(tg_t *tg)
{
	tg_queue_t *queue = NULL;
	ON_LOG(tg, "%s", __func__);
	assert(tg);

	tg_mutex_lock(tg, &tg->queue_lock, 
			ON_ERR(tg, "%s: can't lock queue list", __func__);
			return);
	
	list_for_each(tg->queue, queue)
	{
		if (pthread_mutex_trylock(&queue->lock) == 0){
			queue->loop = false;
			tg_mutex_unlock(&queue->lock);
		}
	}

	list_free(&tg->queue);
	tg_mutex_unlock(&tg->queue_lock);
}

int tg_queue_cancell_queue(tg_t *tg, uint64_t msg_id)
{
	tg_queue_t *queue = tg_queue_cut(tg, msg_id);
	if (queue == NULL){
		ON_ERR(tg, "%s: can't find queue for msg_id: "_LD_""
				, __func__, msg_id);
		return 1;
	}

	// stop query
	tg_mutex_lock(tg, &queue->lock, 
		ON_ERR(tg, "%s: can't lock queue with msg_id: "_LD_"",
			__func__, msg_id);
		return 1);
	queue->loop = false;
	tg_mutex_unlock(&queue->lock); // unlock
	
	return 0;
}

tl_t *tg_send_query(tg_t *tg, buf_t *query){
	return tg_send_query_sync(tg, query);
}
