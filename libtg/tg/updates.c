#include "updates.h"
#include "user.h"
#include "chat.h"
#include "channel.h"
#include "tg.h"
#include "messages.h"
#include "user.h"
#include <pthread.h>
#include <stdint.h>
#include <string.h>
#include "database.h"

#if INTPTR_MAX == INT32_MAX
    #define THIS_IS_32_BIT_ENVIRONMENT
		#define _LD_ "%lld"
#elif INTPTR_MAX == INT64_MAX
    #define THIS_IS_64_BIT_ENVIRONMENT
		#define _LD_ "%ld"
#else
    #error "Environment not 32 or 64-bit."
#endif

#define BUF2STR(_b) strndup((char*)_b.data, _b.size)
#define BUF2IMG(_b) \
	({buf_t i = image_from_photo_stripped(_b); \
	 buf_to_base64(i);}) 


void tg_do_update(tg_t *tg, tl_t *update)
{
	int i;
	ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(update->_id));

	if (!update)
		return;

	switch (update->_id) {
		case id_updateNewMessage:
			{
				tl_updateNewMessage_t *m =
					(tl_updateNewMessage_t *)update;
				tg_message_t tgm;
				tg_message_from_tl_unknown(tg, &tgm, m->message_);
				tg_message_to_database(tg, &tgm);
				ON_UPDATE(tg, TG_UPDATE_MESSAGE, &tgm);
				tg_message_free(&tgm);	
			}
			return;
		
		case id_updateDeleteMessages:
			{
				tl_updateDeleteMessages_t *m =
					(tl_updateDeleteMessages_t *)update;
				for (i = 0; i < m->messages_len; ++i) {
					uint32_t msg_id = m->messages_[i];
					ON_UPDATE(tg, TG_UPDATE_MESSAGE_DELETE, &msg_id);
				}
			}
			return;

		case id_updateUserTyping:
			{
				tl_updateUserTyping_t *m =
					(tl_updateUserTyping_t *)update;
				
				switch (m->action_->_id) {
					case id_sendMessageTypingAction:
						{
							tl_sendMessageTypingAction_t *a = 
								(tl_sendMessageTypingAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_USER_TYPING, &m->user_id_);
						}
						break;
					case id_sendMessageCancelAction:
						{
							tl_sendMessageCancelAction_t *a = 
								(tl_sendMessageCancelAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_USER_CANCEL, &m->user_id_);
						}
						break;
					case id_sendMessageUploadVideoAction:
						{
							tl_sendMessageUploadVideoAction_t *a = 
								(tl_sendMessageUploadVideoAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_USER_UPLOAD_VIDEO, &m->user_id_);
						}
						break;
					case id_sendMessageUploadAudioAction:
						{
							tl_sendMessageUploadAudioAction_t *a = 
								(tl_sendMessageUploadAudioAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_USER_UPLOAD_AUDIO, &m->user_id_);
						}
						break;
					case id_sendMessageUploadPhotoAction:
						{
							tl_sendMessageUploadPhotoAction_t *a = 
								(tl_sendMessageUploadPhotoAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_USER_UPLOAD_PHOTO, &m->user_id_);
						}
						break;
					case id_sendMessageUploadDocumentAction:
						{
							tl_sendMessageUploadDocumentAction_t *a = 
								(tl_sendMessageUploadDocumentAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_USER_UPLOAD_DOCUMENT, &m->user_id_);
						}
						break;
					case id_sendMessageRecordAudioAction:
						{
							tl_sendMessageRecordAudioAction_t *a = 
								(tl_sendMessageRecordAudioAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_USER_RECORD_AUDIO, &m->user_id_);
						}
						break;
					case id_sendMessageRecordRoundAction:
						{
							tl_sendMessageRecordRoundAction_t *a = 
								(tl_sendMessageRecordRoundAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_USER_RECORD_ROUND, &m->user_id_);
						}
						break;

					default:
						break;
				}	
					
			}
			return;

		case id_updateChatUserTyping:
			{
				tl_updateChatUserTyping_t *m =
					(tl_updateChatUserTyping_t *)update;
				tl_peerUser_t *peer = (tl_peerUser_t *)m->from_id_;
				if (peer == NULL)
					break;;	

				struct id {uint64_t chat_id; uint64_t user_id;} id = 
				{m->chat_id_, peer->user_id_};
				
				switch (m->action_->_id) {
					case id_sendMessageTypingAction:
						{
							tl_sendMessageTypingAction_t *a = 
								(tl_sendMessageTypingAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_TYPING, &id);
						}
						break;
					case id_sendMessageCancelAction:
						{
							tl_sendMessageCancelAction_t *a = 
								(tl_sendMessageCancelAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_CANCEL, &id);
						}
						break;
					case id_sendMessageUploadVideoAction:
						{
							tl_sendMessageUploadVideoAction_t *a = 
								(tl_sendMessageUploadVideoAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_UPLOAD_VIDEO, &id);
						}
						break;
					case id_sendMessageUploadAudioAction:
						{
							tl_sendMessageUploadAudioAction_t *a = 
								(tl_sendMessageUploadAudioAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_UPLOAD_AUDIO, &id);
						}
						break;
					case id_sendMessageUploadPhotoAction:
						{
							tl_sendMessageUploadPhotoAction_t *a = 
								(tl_sendMessageUploadPhotoAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_UPLOAD_PHOTO, &id);
						}
						break;
					case id_sendMessageUploadDocumentAction:
						{
							tl_sendMessageUploadDocumentAction_t *a = 
								(tl_sendMessageUploadDocumentAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_UPLOAD_DOCUMENT, &id);
						}
						break;
					case id_sendMessageRecordAudioAction:
						{
							tl_sendMessageRecordAudioAction_t *a = 
								(tl_sendMessageRecordAudioAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_RECORD_AUDIO, &id);
						}
						break;
					case id_sendMessageRecordRoundAction:
						{
							tl_sendMessageRecordRoundAction_t *a = 
								(tl_sendMessageRecordRoundAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_RECORD_ROUND, &id);
						}
						break;

					default:
						break;
				}	
					
			}
			return;

		case id_updateChannelUserTyping:
			{
				tl_updateChannelUserTyping_t *m =
					(tl_updateChannelUserTyping_t *)update;
				tl_peerUser_t *peer = (tl_peerUser_t *)m->from_id_;
				if (peer == NULL)
					break;;	

				struct id {uint64_t chat_id; uint64_t user_id;} id = 
				{m->channel_id_, peer->user_id_};
				
				switch (m->action_->_id) {
					case id_sendMessageTypingAction:
						{
							tl_sendMessageTypingAction_t *a = 
								(tl_sendMessageTypingAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_TYPING, &id);
						}
						break;
					case id_sendMessageCancelAction:
						{
							tl_sendMessageCancelAction_t *a = 
								(tl_sendMessageCancelAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_CANCEL, &id);
						}
						break;
					case id_sendMessageUploadVideoAction:
						{
							tl_sendMessageUploadVideoAction_t *a = 
								(tl_sendMessageUploadVideoAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_UPLOAD_VIDEO, &id);
						}
						break;
					case id_sendMessageUploadAudioAction:
						{
							tl_sendMessageUploadAudioAction_t *a = 
								(tl_sendMessageUploadAudioAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_UPLOAD_AUDIO, &id);
						}
						break;
					case id_sendMessageUploadPhotoAction:
						{
							tl_sendMessageUploadPhotoAction_t *a = 
								(tl_sendMessageUploadPhotoAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_UPLOAD_PHOTO, &id);
						}
						break;
					case id_sendMessageUploadDocumentAction:
						{
							tl_sendMessageUploadDocumentAction_t *a = 
								(tl_sendMessageUploadDocumentAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_UPLOAD_DOCUMENT, &id);
						}
						break;
					case id_sendMessageRecordAudioAction:
						{
							tl_sendMessageRecordAudioAction_t *a = 
								(tl_sendMessageRecordAudioAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_RECORD_AUDIO, &id);
						}
						break;
					case id_sendMessageRecordRoundAction:
						{
							tl_sendMessageRecordRoundAction_t *a = 
								(tl_sendMessageRecordRoundAction_t *)m->action_; 
							ON_UPDATE(tg, TG_UPDATE_CHAT_USER_RECORD_ROUND, &id);
						}
						break;

					default:
						break;
				}	
					
			}
			return;

		case id_updateUserStatus:
			{
				tl_updateUserStatus_t *m =
					(tl_updateUserStatus_t *)update;
				struct id {uint64_t user_id; TG_USER_STATUS status;} id =
				{m->user_id_};
				switch (m->status_->_id) {
					case id_userStatusEmpty:
						id.status = TG_USER_STATUS_EMPTY;
						break;
					case id_userStatusOnline:
						id.status = TG_USER_STATUS_ONLINE;
						break;
					case id_userStatusOffline:
						id.status = TG_USER_STATUS_OFFLINE;
						break;
					case id_userStatusRecently:
						id.status = TG_USER_STATUS_RECENTLY;
						break;
					case id_userStatusLastWeek:
						id.status = TG_USER_STATUS_LASTWEEK;
						break;
					case id_userStatusLastMonth:
						id.status = TG_USER_STATUS_LASTMONTH;
						break;
					
					default:
						break;
				}
				ON_UPDATE(tg, TG_UPDATE_USER_STATUS, &id);
			}
			return;
		
			
		default:
			break;
			
	}
	ON_LOG(tg, "%s: don't now how to handle update: %s",
			__func__, TL_NAME_FROM_ID(update->_id));
}

static uint64_t message_update(tg_t *tg, 
		tg_message_t *msg, tl_t *tl)
{
	memset(msg, 0, sizeof(tg_message_t));
	uint64_t chat_id = 0;
	
	tl_updateShortMessage_t up;
	if (tl->_id == id_updateShortChatMessage)
	{
		tl_updateShortChatMessage_t *cm =
		 (tl_updateShortChatMessage_t *)tl;;
		up.out_ = cm->out_;
		up.mentioned_ = cm->mentioned_;
		up.media_unread_ = cm->media_unread_;
		up.silent_ = cm->silent_;
		up.id_ = cm->_id;
		msg->from_id_ = cm->from_id_;	
		chat_id = cm->chat_id_;
		up.message_ = cm->message_;
		up.date_ = cm->date_;
		/* TODO: fwd_from and reply_to <03-01-25, yourname> */	
		up.ttl_period_ = cm->ttl_period_;
		/* TODO: entities <03-01-25, yourname> */
	}
	else
		up = *(tl_updateShortMessage_t *)tl;

	msg->out_ = up.out_;
	msg->mentioned_ = up.mentioned_;
	msg->media_unread_ = up.media_unread_;
	msg->silent_ = up.silent_;
	msg->id_ = up.id_;
	msg->message_ = BUF2STR(up.message_); 
	msg->date_ = up.date_;
	/* TODO: fwd_from and reply_to <03-01-25, yourname> */	
	msg->ttl_period_ = up.ttl_period_;
	/* TODO: entities <03-01-25, yourname> */

	/*tg_message_to_database(tg, msg);*/

	// save message to database
	//pthread_mutex_lock(&tg->databasem); // lock
	//struct str s;
	//str_init(&s);
	//str_appendf(&s,
		//"INSERT INTO \'messages\' (\'msg_id\') "
		//"SELECT %d "
		//"WHERE NOT EXISTS (SELECT 1 FROM messages WHERE msg_id = %d);\n"
	//, msg->id_, msg->id_);
	//str_appendf(&s, "UPDATE \'messages\' SET ");
	//if (msg->message_ && msg->message_[0]){
		//str_appendf(&s, "\'message\'" " = \'");
		//str_append(&s, (char*)msg->message_, strlen((char*)msg->message_));
		//str_appendf(&s, "\', ");
	//}
	//str_appendf(&s, "\'out\'" " = "_LD_", ", (uint64_t)msg->out_);
	//str_appendf(&s, "\'mentioned\'" " = "_LD_", ", (uint64_t)msg->mentioned_);
	//str_appendf(&s, "\'media_unread\'" " = "_LD_", ", (uint64_t)msg->media_unread_);
	//str_appendf(&s, "\'silent\'" " = "_LD_", ", (uint64_t)msg->silent_);
	//str_appendf(&s, "\'date\'" " = "_LD_", ", (uint64_t)msg->date_);
	//str_appendf(&s, "\'ttl_period\'" " = "_LD_", ", (uint64_t)msg->ttl_period_);
	//str_appendf(&s, "id = %d WHERE msg_id = %d;\n"
			//, tg->id, msg->id_);
	//tg_sqlite3_exec(tg, s.str);
	//pthread_mutex_unlock(&tg->databasem); // unlock
	/*free(s.str);*/
	return chat_id;
}

int tg_do_updates(tg_t *tg, tl_t *tl)
{
	if (!tl)
		return 1;

	int i;

	switch (tl->_id) {
		case id_updatesTooLong:
			ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(tl->_id));
			return 0;
		
		case id_updateShortMessage:
			ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(tl->_id));
			{
				tg_message_t msg;
				message_update(tg, &msg, tl);	

				// callback update
				ON_UPDATE(tg, TG_UPDATE_MESSAGE, &msg);

				// free mem
				free(msg.message_);
			}
			return 0;
		
		case id_updateShortChatMessage:
			ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(tl->_id));
			{
				tg_message_t msg;
				uint64_t chat_id = message_update(tg, &msg, tl);	
				
				// callback update
				struct {uint64_t a; tg_message_t b;} id =
					{chat_id, msg};
				ON_UPDATE(tg, TG_UPDATE_CHAT_MESSAGE, &id);
				
				// free mem
				free(msg.message_);
			}
			return 0;
		
		case id_updateShort:
			ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(tl->_id));
			{
				tl_updateShort_t *up = (tl_updateShort_t *)tl; 
				tg_do_update(tg, up->update_);
			}
			return 0;

		case id_updatesCombined:
			ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(tl->_id));
			{
				tl_updatesCombined_t *up = (tl_updatesCombined_t *)tl; 
				
				// handle users
				//tg_users_save(tg, up->users_len, up->users_);
				
				// handle chats
				/*tg_chats_save(tg, up->chats_len, up->chats_);*/

				// handle updates
				for (i = 0; i < up->updates_len; ++i) {
					if (up->updates_ == NULL || 
							up->updates_[i] == NULL)
						continue;
					tg_do_update(tg, up->updates_[i]);
				}
			}
			return 0;

		case id_updates:
			ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(tl->_id));
			{
				tl_updates_t *up = (tl_updates_t *)tl; 
				
				// handle users
				/*tg_users_save(tg, up->users_len, up->users_);*/
				
				// handle chats
				/*tg_chats_save(tg, up->chats_len, up->chats_);*/

				// handle updates
				for (i = 0; i < up->updates_len; ++i) {
					if (up->updates_ == NULL || 
							up->updates_[i] == NULL)
						continue;
					tg_do_update(tg, up->updates_[i]);
				}
			}
			return 0;

		case id_updateShortSentMessage:
			ON_LOG(tg, "%s: %s", __func__, TL_NAME_FROM_ID(tl->_id));
			return 0;

		default:
			break;
	}

	ON_LOG(tg, "%s: object is not updates: %s",
			__func__, TL_NAME_FROM_ID(tl->_id));
	return 1;
}
