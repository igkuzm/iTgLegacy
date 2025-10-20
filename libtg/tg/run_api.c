#include "list.h"
#include "tg.h"
#include "../transport/transport.h"
#include "../transport/net.h"
#include "updates.h"
#include <stdint.h>
#include <unistd.h>
#include <sys/socket.h>
#include "../tl/alloc.h"
#if INTPTR_MAX == INT32_MAX
    #define THIS_IS_32_BIT_ENVIRONMENT
		#define _LD_ "%lld"
#elif INTPTR_MAX == INT64_MAX
    #define THIS_IS_64_BIT_ENVIRONMENT
		#define _LD_ "%ld"
#else
    #error "Environment not 32 or 64-bit."
#endif


tl_t * tg_deserialize(tg_t *tg, buf_t *buf)
{
	int i;
	tl_t *tl = tl_deserialize(buf);
	if (tl == NULL){
		ON_ERR(tg, "%s: can't deserialize data", __func__);
		return NULL;
	}
	ON_LOG(tg, "%s: handle %s", __func__, 
			TL_NAME_FROM_ID(tl->_id));

	switch (tl->_id) {
		case id_msg_container:
			{
				tl_msg_container_t *obj = 
					(tl_msg_container_t *)tl;
				ON_LOG(tg, "msg container with %d messages", obj->messages_len);
				// catch result
				tl_t *result = NULL;
				for (i = 0; i < obj->messages_len; ++i) {
					mtp_message_t m = obj->messages_[i];
					// add msgid to ack
					//tg_add_mgsid(tg, m.msg_id);
					tl = tg_deserialize(tg, &m.body);	
					ON_LOG(tg, "msg container: message #%d: %s", 
							i, TL_NAME_FROM_ID(tl->_id));
					if (tl && tl->_id == id_rpc_result)
					{
						tl_rpc_result_t *res = (tl_rpc_result_t *)tl;
						ON_LOG(tg, "msg container: message #%d: result: %s", 
								i, 
								res->result_?TL_NAME_FROM_ID(res->result_->_id):"NULL");
						result = tl;
						if (res->result_->_id == id_rpc_error)
							{
								char *err = tg_strerr(res->result_);
								ON_ERR(tg, "msg container: message #%d: %s", i, err);
								free(err);
							}
					}
				}
				if (result)
					return result;
			}
			break;
		case id_new_session_created:
			{
				tl_new_session_created_t *obj = 
					(tl_new_session_created_t *)tl;
				// handle new session
				ON_LOG(tg, "new session created...");
			}
			break;
		case id_pong:
			{
				tl_pong_t *obj = 
					(tl_pong_t *)tl;
				// handle pong
				ON_LOG(tg, "pong...");
			}
			break;
		case id_bad_msg_notification:
			{
				tl_bad_msg_notification_t *obj = 
					(tl_bad_msg_notification_t *)tl;
				// handle bad msg notification
				char *err = tg_strerr(tl);
				ON_ERR(tg, "%s", err);
				free(err);
				return NULL;
			}
			break;
		case id_rpc_error:
			{
				char *err = tg_strerr(tl);
				ON_ERR(tg, "%s", err);
				free(err);
				return NULL;
			}
			break;

		default:
			break;
	}

	return tl;
}

tl_t *tg_result(tg_t *tg, tl_t *result)
{
	tl_t *tl = result;
	printf("%s: handle result with tl: %s\n", 
			__func__, TL_NAME_FROM_ID(result->_id));
	switch (result->_id) {
		case id_gzip_packed:
			{
				// handle gzip
				tl_gzip_packed_t *obj =
					(tl_gzip_packed_t *)result;

				buf_t buf;
				int _e = gunzip_buf(&buf, obj->packed_data_);
				if (_e)
				{
					char *err = gunzip_buf_err(_e);
					ON_ERR(tg, "%s: %s", __func__, err);
					free(err);
				}
				tl = tg_deserialize(tg, &buf);
			}
			break;
		case id_bad_msg_notification:
			{
				tl_bad_msg_notification_t *obj = 
					(tl_bad_msg_notification_t *)tl;
				// handle bad msg notification
				char *err = tg_strerr(tl);
				ON_ERR(tg, "%s", err);
				free(err);
				return NULL;
			}
			break;
		case id_rpc_error:
			{
				char *err = tg_strerr(tl);
				ON_ERR(tg, "%s", err);
				free(err);
				return NULL;
			}
			break;

		default:
			break;
	}

	return tl;
}

tl_t *tg_run_api_with_progress(tg_t *tg, buf_t *query, 
		void *progressp, 
		int (*progress)(void *progressp, int size, int total))
{
	// session id
	if (!tg->ssid.size)
		tg->ssid = buf_rand(8);
	if (!tg->salt.size)
		tg->salt = buf_rand(8);

	int i;
	tl_t *tl = NULL;

	// prepare query
	uint64_t msgid = 0;
	buf_t b = tg_prepare_query(
			tg, *query, true, &msgid);
	if (!b.size)
		goto tg_run_api_end;

	// open socket - on port 80
	int sockfd = tg_net_open_port(tg, 80);
	if (sockfd < 0)
		goto tg_run_api_end;

	// send query
	/*ON_LOG(tg, "%s: send: %s", __func__, buf_sdump(b));*/
	int s = 
		send(sockfd, b.data, b.size, 0);
	if (s < 0){
		ON_ERR(tg, "%s: socket error: %d", __func__, s);
		goto tg_run_api_end;
	}

	// receive data
tg_run_api_receive_data:;
	// send ACK
	if (tg->msgids[0]){
		buf_t ack = tg_ack(tg);
		int s = 
			send(sockfd, ack.data, ack.size, 0);
		buf_free(ack);
		if (s < 0){
			ON_ERR(tg, "%s: socket error: %d", __func__, s);
			goto tg_run_api_end;
		}
	}

	buf_t r = buf_new();
	// get length of the package
	uint32_t len;
	recv(sockfd, &len, 4, 0);
	ON_LOG(tg, "%s: prepare to receive len: %d", __func__, len);
	if (len < 0) {
		// this is error - report it
		ON_ERR(tg, "%s: received wrong length: %d", __func__, len);
		buf_free(r);
		goto tg_run_api_end;
	}

	// realloc buf to be enough size
	if (buf_realloc(&r, len)){
		// handle error
		ON_ERR(tg, "%s: error buf realloc to size: %d", __func__, len);
		buf_free(r);
		goto tg_run_api_end;
	}

	// get data
	uint32_t received = 0; 
	while (received < len){
		int s = 
			recv(sockfd, &r.data[received], len - received, 0);	
		if (s<0){
			ON_ERR(tg, "%s: socket error: %d", __func__, s);
			buf_free(r);
			goto tg_run_api_end;
		}
		ON_LOG(tg, "%s: received chunk: %d", __func__, s);

		received += s;
		
		// ask to send new chunk
		if (received < len){
			ON_LOG(tg, "%s: expected size: %d, received: %d (%d%%)", 
					__func__, len, received, received*100/len);
			if (progress)
				if (progress(progressp, received, len))
					break;
			
			// receive more data
			continue;
		}
		break;
	}

	ON_LOG(tg, "%s: expected size: %d, received: %d (%d%%)", 
			__func__, len, received, received*100/len);

	if (received < len){
		// some error
		ON_ERR(tg, "%s: can't receive data", __func__);
		buf_free(r);
		tg_net_close(tg, sockfd);
		goto tg_run_api_end;
	}

	// get payload 
	r.size = len;
	if (r.size == 4 && buf_get_ui32(r) == 0xfffffe6c){
		buf_free(r);
		tg_net_close(tg, sockfd);
		goto tg_run_api_end;
	}

	buf_t d = tg_decrypt(tg, r, true);
	if (!d.size){
		buf_free(r);
		tg_net_close(tg, sockfd);
		goto tg_run_api_end;
	}
	buf_free(r);

	buf_t msg = tg_deheader(tg, d, true);
	if (!msg.size){
		buf_free(d);
		tg_net_close(tg, sockfd);
		goto tg_run_api_end;
	}
	buf_free(d);

	// deserialize 
	tl = tg_deserialize(tg, &msg);
	
	// handle tl
	if (tl == NULL){
		tg_net_close(tg, sockfd);
		goto tg_run_api_end;
	}

	if (tl->_id == id_rpc_error)
	{
		char *err = tg_strerr(tl);
		ON_ERR(tg, "RPC_ERROR: %s", err);
		free(err);
		tl_free(tl);
		return NULL;
	}

	if (tl->_id == id_msgs_ack)
	{
		tl_free(tl);
		// receive data again
		goto tg_run_api_receive_data;
	}

	if (tl->_id != id_rpc_result && 
			tl->_id != id_msg_detailed_info &&
			tl->_id != id_msg_new_detailed_info)
	{
		// BAD SERVER SALT
		if (tl->_id == id_bad_server_salt){
			// free tl
			tl_free(tl);
			// close socket
			tg_net_close(tg, sockfd);
			// resend message
			return tg_run_api_with_progress(
					tg, query, progressp, progress);
		}

		// handle UPDATES
		if (tg_do_updates(tg, tl))
			ON_ERR(tg, "%s: expected rpc_result, but got: %s", 
				__func__, TL_NAME_FROM_ID(tl->_id));
		// free tl
		tl_free(tl);
		// receive data again
		goto tg_run_api_receive_data;
	} 

	// check info
	if (tl->_id == id_msg_detailed_info){
		tl_msg_detailed_info_t *di = 
			(tl_msg_detailed_info_t *)tl;
		if (msgid == di->answer_msg_id_){
			// ok - we got responce
			// free tl
			tl_free(tl);
			// close socket
			tg_net_close(tg, sockfd);
			return NULL;
		} else {
			// free tl
			tl_free(tl);
			// receive data again
			goto tg_run_api_receive_data;
		}
	}
	if (tl->_id == id_msg_new_detailed_info){
		tl_msg_new_detailed_info_t *di = 
			(tl_msg_new_detailed_info_t *)tl;
		if (msgid == di->answer_msg_id_){
			// ok - we got responce
			// free tl
			tl_free(tl);
			// close socket
			tg_net_close(tg, sockfd);
			return NULL;
		} else {
			// free tl
			tl_free(tl);
			// receive data again
			goto tg_run_api_receive_data;
		}
	}

	// check msgid
	tl_rpc_result_t *result = (tl_rpc_result_t *)tl;
	if (msgid != result->req_msg_id_){
		ON_ERR(tg, 
				"RPC_RESULT: %s with wrong msg id: "_LD_" vs "_LD_"", 
				result->result_?TL_NAME_FROM_ID(result->result_->_id):"NULL", 
				msgid, result->req_msg_id_);
		// free tl
		tl_free(tl);
		// receive data again
		//goto tg_run_api_receive_data;
		// close socket
		tg_net_close(tg, sockfd);
		// resend message
		//return tg_run_api_with_progress(
				//tg, query, progressp, progress);
		return NULL;
	}
	
	// close socket
	tg_net_close(tg, sockfd);
	
	// handle result
	if (result->result_ == NULL){
		ON_ERR(tg, "%s: rpc result is NULL", __func__);
		// free tl
		tl_free(tl);
		tl = NULL;
		goto tg_run_api_end;
	}
	ON_LOG(tg, "GOT RESULT!: %s", TL_NAME_FROM_ID(tl->_id));
	tl = tg_result(tg, result->result_);

tg_run_api_end:;
	buf_free(b);
	return tl;	
}

tl_t *tg_run_api(tg_t *tg, buf_t *query){
	return tg_run_api_with_progress(
			tg, query, NULL, NULL);
}

struct run_api {
	uint64_t msgid;	
	void *userdata;
	int (*callback)(void *userdata, tl_t *tl);
};

void tg_run_api_async_receive(tg_t *tg, tl_t *tl) 
{
	// handle tl
	if (tl->_id != id_rpc_result){
		
		// BAD SERVER SALT
		if (tl->_id == id_bad_server_salt){
			// free tl
			tl_free(tl);
			// resend message
			return;
		}

		// handle UPDATES
		if (tg_do_updates(tg, tl))
			ON_ERR(tg, "%s: expected rpc_result, but got: %s", 
				__func__, TL_NAME_FROM_ID(tl->_id));
		// free tl
		tl_free(tl);
		return;
	} 
	
	// check msgid
	tl_rpc_result_t *result = (tl_rpc_result_t *)tl;
	uint64_t msgid = result->req_msg_id_;

	// find api in queue
	struct run_api *api = NULL;
	int i, index = -1;
	list_for_each(tg->receive_queue, api){
		if (api->msgid == msgid){
			index = i;
			break;
		}
		i++;
	};
	if (index == -1){
		ON_ERR(tg, "%s: can't find api for msg_id: "_LD_"", 
				__func__, msgid);
		tl_free(tl);
		return;
	}

	// get api
	if (api == NULL){
		ON_ERR(tg, "%s: list_remove error", __func__);
		tl_free(tl);
		return;
	}
	
	// handle result
	if (result->result_ == NULL){
		ON_ERR(tg, "%s: rpc result is NULL", __func__);
		// free tl
		tl_free(tl);
		return;
	}

	tl = tg_result(tg, result->result_);
	if (api->callback)
		api->callback(api->userdata, tl);

	// free
	if (tl)
		tl_free(tl);
	
	//list_remove(&tg->receive_queue, index);
}

void tg_run_api_async(tg_t *tg, buf_t *query,
		void *userdata, 
		int (*callback)(void *userdata, tl_t *tl))
{
	// session id
	if (!tg->ssid.size)
		tg->ssid = buf_rand(8);
	if (!tg->salt.size)
		tg->salt = buf_rand(8);

	int i;
	tl_t *tl = NULL;

	// prepare query
	uint64_t msgid = 0;
	buf_t b = tg_prepare_query(
			tg, *query, true, &msgid);
	if (!b.size)
	{
		ON_ERR(tg, "%s: can't prepare query", __func__);
		buf_free(b);
		return;
	}

	// open socket
	int sockfd = tg_net_open(tg);
	tg->queue_sockfd = sockfd;
	if (sockfd < 0)
	{
		ON_ERR(tg, "%s: can't open socket", __func__);
		buf_free(b);
		return;
	}

	// send ACK
	if (tg->msgids[0]){
		buf_t ack = tg_ack(tg);
		int s = 
			send(sockfd, ack.data, ack.size, 0);
		buf_free(ack);
		if (s < 0){
			ON_ERR(tg, "%s: socket error: %d", __func__, s);
			buf_free(b);
			return;
		}
	}

	// add api to queue list
	struct run_api *api = NEW(struct run_api, 
			ON_ERR(tg, "%s: can't allocate memory", __func__);
			return;);
	api->msgid = msgid;
	api->callback = callback;
	api->userdata = userdata;

	list_add(&tg->receive_queue, api); 

	// send query
	/*ON_LOG(tg, "%s: msgid: "_LD_", send: %s", */
			/*__func__, msgid, buf_sdump(b));*/
	int s = 
		send(sockfd, b.data, b.size, 0);
	if (s < 0){
		ON_ERR(tg, "%s: socket error: %d", __func__, s);
		buf_free(b);
		return;
	}

	// close socket
	//tg_net_close(tg, sockfd);
}
