#include "answer.h"
#include "tg.h"
#include "updates.h"
#if INTPTR_MAX == INT32_MAX
    #define THIS_IS_32_BIT_ENVIRONMENT
		#define _LD_ "%lld"
#elif INTPTR_MAX == INT64_MAX
    #define THIS_IS_64_BIT_ENVIRONMENT
		#define _LD_ "%ld"
#else
    #error "Environment not 32 or 64-bit."
#endif

// return 1 if msgid mismatch
int tg_parse_answer(tg_t *tg, tl_t *tl, uint64_t msg_id,
		void *ptr, int (*callback)(void *ptr, const tl_t *tl))
{
	int ret = 1;
	ON_LOG(tg, "%s: %s", __func__,
			tl?TL_NAME_FROM_ID(tl->_id):"NULL");

	if (tl == NULL){
		return ret;
	}

	switch (tl->_id) {
		case id_rpc_result:
			{
				// add to ack
				tg_add_msgid(tg, msg_id);
				
				// handle result
				tl_rpc_result_t *rpc_result = 
					(tl_rpc_result_t *)tl;
				tl_t *result = rpc_result->result_;
				ON_LOG(tg, "got msg result: (%s) for msg_id: "_LD_"",
					result?TL_NAME_FROM_ID(result->_id):"NULL", 
					rpc_result->req_msg_id_); 
				if (msg_id == rpc_result->req_msg_id_){
					// got result!
					ret = 0;
					ON_LOG(tg, "OK! We have result: %s", 
						result?TL_NAME_FROM_ID(result->_id):"NULL");
					if (callback)
						if (callback(ptr, result))
							break;
				} else {
					ON_ERR(tg, "rpc_result: (%s) for wrong msg_id: "_LD_"",
						result?TL_NAME_FROM_ID(result->_id):"NULL",
						rpc_result->req_msg_id_); 
					// drop!
					/*tg_add_todrop(tg, rpc_result->req_msg_id_);*/
				}
			}
			break;
		
		case id_msg_detailed_info:
		case id_msg_new_detailed_info:
			{
				uint64_t msg_id_;
				if (tl->_id == id_msg_detailed_info)
					msg_id_ = ((tl_msg_detailed_info_t *)tl)->answer_msg_id_;
				else
					msg_id_ = ((tl_msg_new_detailed_info_t *)tl)->answer_msg_id_;
				if (msg_id == msg_id_){
					ON_LOG(tg, "answer has been already sended!");
					ret = 0;
					// add to ack
					tg_add_msgid(tg, msg_id_);
					
					if (callback)
						if (callback(ptr, tl))
							break;

				} else {
					ON_ERR(tg, "%s: %s for wrong msgid: "_LD_"",
							__func__, TL_NAME_FROM_ID(tl->_id), msg_id_);
				}
			}
			break;
		
		case id_rpc_error:
		case id_bad_msg_notification:
			{
				// show error
				char *err = tg_strerr(tl);
				ON_ERR(tg, "%s: %s", __func__, err);
				free(err);
				
				// add time diff
				pthread_mutex_lock(&tg->seqnm);
				tg->timediff = ntp_time_diff();
				pthread_mutex_unlock(&tg->seqnm);
			}
			break; // run on_done
		
		case id_updatesTooLong: case id_updateShort:
		case id_updateShortMessage: case id_updateShortChatMessage:
		case id_updateShortSentMessage: case id_updatesCombined:
		case id_updates:
			// do updates
			ON_LOG(tg, "%s: got updates", __func__);
			tg_do_updates(tg, tl);
			break;

		case id_msg_container:
			{
				tl_msg_container_t *container = 
					(tl_msg_container_t *)tl; 
				ON_LOG(tg, "%s: container %d long", 
						__func__, container->messages_len);
				int i;
				for (i = 0; i < container->messages_len; ++i) {
					mtp_message_t m = container->messages_[i];
					// parse answer for each message
					tl_t *tl = tl_deserialize(&m.body);
					tg_parse_answer(tg, tl, msg_id, ptr, callback);
					// free tl
					tl_free(tl);
				}
			}
			break;

		case id_gzip_packed:
			{
				// handle gzip
				tl_t *tl = tg_tl_from_gzip(tg, tl);
				tg_parse_answer(tg, tl, msg_id, ptr, callback);
				// free tl
				tl_free(tl);
			}
			break;

		case id_new_session_created:
			{
				// handle new session
				ON_LOG(tg, "new session created...");
			}
			break;
		
		case id_msgs_ack:
			{
				tl_msgs_ack_t *ack = (tl_msgs_ack_t *)tl;
				// check msg_id
				int i;
				for (i = 0; i < ack->msg_ids_len; ++i) {
					if (msg_id == ack->msg_ids_[i]){
						ret = 0;
						ON_LOG(tg, "ACK for result!");
						if (callback)
							if (callback(ptr, tl))
								break;
					}
				}
			}
			break;

		default:
			ON_LOG(tg, "%s: don't know how to handle: %s", __func__,
					TL_NAME_FROM_ID(tl->_id));
			break;
	}

	return ret;
}
