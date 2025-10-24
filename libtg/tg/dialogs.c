/**
 * File              : dialogs.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 29.11.2024
 * Last Modified Date: 24.10.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "channel.h"
#include "chat.h"
#include "user.h"
#include "tg.h"
#include "../tl/id.h"
#include "../tl/alloc.h"
#include "../mtx/include/net.h"
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "time.h"
#include "../tl/alloc.h"
#include "dialogs.h"
#include "pthread.h"
#include "database.h"
#include <unistd.h>
#include "net.h"
#include <string.h>
#include <assert.h>
#include "peer.h"
#include "messages.h"

// #include <stdint.h>
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

static int tg_dialogs_from_tl(
		tg_t *tg, const tl_t *tl,
		uint64_t *hash,
		void *data,
		int (*callback)(void *data, const tg_dialog_t *dialog))
{
	int i, n=0;

	if (!tl){
		return 0;
	}

	if (tl->_id == id_messages_dialogsNotModified){
		ON_LOG(tg, "%s: dialogs not modified", __func__);
		tl_messages_dialogsNotModified_t *dnm =
			(tl_messages_dialogsNotModified_t *)tl;
		/* TODO:  <21-12-24, yourname> */
		return 0;
	}

	if ((tl->_id == id_messages_dialogsSlice) ||
	    (tl->_id == id_messages_dialogs))
	{
		tl_messages_dialogs_t *md;
		bool free_md = false;

		if (tl->_id == id_messages_dialogsSlice)
		{
			tl_messages_dialogsSlice_t *mds = 
				(tl_messages_dialogsSlice_t *)tl;
			ON_LOG(tg, "DIALOG SLISE len: %d", mds->count_);
			ON_LOG(tg, "DIALOG SLISE dialogs: %d", mds->dialogs_len);
			ON_LOG(tg, "DIALOG SLISE chats: %d", mds->chats_len);
			ON_LOG(tg, "DIALOG SLISE users: %d", mds->users_len);

			md = NEW(tl_messages_dialogs_t, return 0;);
			free_md = true;

			md->dialogs_ = mds->dialogs_;
			md->dialogs_len = mds->dialogs_len;
			md->chats_ = mds->chats_;
			md->chats_len = mds->chats_len;
			md->messages_ = mds->messages_;
			md->messages_len = mds->messages_len;
			md->users_ = mds->users_;
			md->users_len = mds->users_len;
		}

		if (tl->_id == id_messages_dialogs)
		{
			md = (tl_messages_dialogs_t *)tl;
		}

		if (md->dialogs_ == NULL){
			ON_ERR(tg, "dialogs pointer is NULL!");
			return 0;
		}
		
		ON_LOG(tg, 
				"%s: got %d dialogs with %d messages, %d chats and %d users", 
				__func__, md->dialogs_len, md->messages_len, 
				md->chats_len, md->users_len);

		// update users
		tg_users_save(tg, md->users_len, md->users_);
		// update chats
		tg_chats_save(tg, md->chats_len, md->chats_);
		
		for (i = 0; i < md->dialogs_len; ++i) {
			if (md->dialogs_[i] == NULL)
				continue;

			ON_LOG(tg, "dialog #%d: %s\n", 
					i, TL_NAME_FROM_ID(md->dialogs_[i]->_id));
			// handle dialogs
			tg_dialog_t d;
			memset(&d, 0, sizeof(d));
			
			tl_dialog_t *dialog = NULL;
			bool free_dialog = false;

			tl_peerChat_t *peer = NULL;
			tl_peerNotifySettings_t *pns = NULL; 
			
			if (md->dialogs_[i]->_id == id_dialogFolder){
				tl_dialogFolder_t *df = 
					(tl_dialogFolder_t *)md->dialogs_[i];
				tl_folder_t *folder = 
					(tl_folder_t *)df->folder_;

				dialog = NEW(tl_dialog_t, return 0;);
				free_dialog = true;

				dialog->peer_ = df->peer_;
				dialog->top_message_ = df->top_message_;
				dialog->pinned_ = df->pinned_;
				dialog->unread_count_ = df->unread_unmuted_messages_count_;
				dialog->folder_id_ = folder->id_;
				peer = (tl_peerChat_t *)df->peer_;

			} else if (md->dialogs_[i]->_id != id_dialog){
				ON_LOG(tg, "%s: unknown dialog type: %.8x",
						__func__, md->dialogs_[i]->_id);
				continue;
			
			} else {
				dialog = (tl_dialog_t *)md->dialogs_[i];	
				peer = (tl_peerChat_t *)dialog->peer_;
				pns = (tl_peerNotifySettings_t *)dialog->notify_settings_;
			}

			d.top_message_id = dialog->top_message_;
			
			d.pinned = dialog->pinned_;
			d.unread_mark = dialog->unread_mark_;
			d.read_inbox_max_id = dialog->read_inbox_max_id_;
			d.read_outbox_max_id = dialog->read_outbox_max_id_;
			d.unread_count = dialog->unread_count_;
			d.unread_mentions_count = dialog->unread_mentions_count_;
			d.unread_reactions_count = dialog->unread_reactions_count_;
			d.folder_id = dialog->folder_id_;
			
			if (peer){
				d.peer_id = peer->chat_id_;
			}

			if (pns){
				d.silent = pns->silent_;
				d.mute_until = pns->mute_until_;
			}

			int k;

			// iterate users
			for (k = 0; k < md->users_len; ++k) {
				// skip on NULL
				if (!md->users_){
					ON_ERR(tg, "%s line: %d: object is NULL!", __func__, __LINE__);
					break;
				}
				if (!md->users_[k]){
					ON_LOG(tg, "%s line: %d: object is NULL!", __func__, __LINE__);
					continue;
				}

				switch (md->users_[k]->_id) {
					case id_user:
						{
							tl_user_t *user = 
								(tl_user_t *)md->users_[k];
							
							if (d.peer_id == user->id_)
							{
								d.access_hash = user->access_hash_;
								d.peer_type = TG_PEER_TYPE_USER;
								if (user->username_.size)
									d.name = BUF2STR(user->username_);
								else
									d.name = BUF2STR(user->first_name_);
							
								if (user->photo_ && 
										user->photo_->_id == id_userProfilePhoto)
								{
									tl_userProfilePhoto_t *photo = 
										(tl_userProfilePhoto_t *)user->photo_; 
									d.photo_id = photo->photo_id_;
									d.thumb = BUF2IMG(photo->stripped_thumb_);
								}
							}
						}
						break;
				 default:
						break;
				}
			}

			// iterate chats
			for (k = 0; k < md->chats_len; ++k) {
				// skip on NULL
				if (!md->chats_){
					ON_ERR(tg, "%s line: %d: object is NULL!", __func__, __LINE__);
					break;
				}
				if (!md->chats_[k]){
					ON_LOG(tg, "%s line: %d: object is NULL!", __func__, __LINE__);
					continue;
				}
			
				switch (md->chats_[k]->_id) {
					case id_channel:
						{
							tl_channel_t *channel = 
								(tl_channel_t *)md->chats_[k];
							if (d.peer_id == channel->id_)
							{
								d.access_hash = channel->access_hash_;
								d.peer_type = TG_PEER_TYPE_CHANNEL;
								d.name = BUF2STR(channel->title_);
								d.broadcast = channel->broadcast_;
								if (channel->photo_ && 
									channel->photo_->_id == id_chatPhoto)
								{
									tl_chatPhoto_t *photo = 
										(tl_chatPhoto_t *)channel->photo_; 
									d.photo_id = photo->photo_id_;
									d.thumb = BUF2IMG(photo->stripped_thumb_);
								}
							}
						}
						break;
					
					case id_chat:
						{
							tl_chat_t *chat = 
								(tl_chat_t *)md->chats_[k];
							if (d.peer_id == chat->id_)
							{
								d.peer_type = TG_PEER_TYPE_CHAT;
								d.name = BUF2STR(chat->title_);
								if (chat->photo_ && 
									chat->photo_->_id == id_chatPhoto)
								{
									tl_chatPhoto_t *photo = 
										(tl_chatPhoto_t *)chat->photo_; 
									d.photo_id = photo->photo_id_;
									d.thumb = BUF2IMG(photo->stripped_thumb_);
								}
							}
						}
						break;
					
					default:
						break;
				}
			}

			if (d.peer_type == TG_PEER_TYPE_NULL) {
				ON_LOG(tg, "%s: can't find dialog data "
						"for peer: (%s): "_LD_"",
						__func__, TL_NAME_FROM_ID(peer->_id), peer->chat_id_);
				// free
				tg_dialog_free(&d);
				continue;
			}

			// iterate messages
			for (k = 0; k < md->messages_len; ++k){
				if (!md->messages_){
					ON_ERR(tg, "%s line: %d: object is NULL!", __func__, __LINE__);
					break;;
				}
				if (!md->messages_[k]){
					ON_LOG(tg, "%s line: %d: object is NULL!", __func__, __LINE__);
					continue;
				}
				if (md->messages_[k]->_id == id_message)
				{
					tl_message_t *message = 
						(tl_message_t *)md->messages_[k];
					if (message->id_ == d.top_message_id){
						
						// save message to database
						tg_message_t tgm;
						tg_message_from_tl(tg, &tgm, message);

						// update dialog
						d.top_message_date = message->date_;

						// set message text
						if (message->message_.size)
							d.top_message_text = BUF2STR(message->message_);
						else if (tgm.doc_isVideo)
							d.top_message_text = strdup("*video*");
						else if (tgm.doc_isRound)
							d.top_message_text = strdup("*round*");
						else if (tgm.doc_isVoice)
							d.top_message_text = strdup("*voice message*");
						else if (tgm.doc_title)
							d.top_message_text = strdup(tgm.doc_title);
						else if (tgm.doc_id)
							d.top_message_text = strdup("*document*");
						else if (tgm.media_type == id_messageMediaDocument)
							d.top_message_text = strdup("*document*");
						else if (tgm.media_type == id_messageMediaContact)
							d.top_message_text = strdup("*contact*");
						else if (tgm.media_type == id_messageMediaPhoto)
							d.top_message_text = strdup("*photo*");
						else if (tgm.media_type == id_messageMediaGeo)
							d.top_message_text = strdup("*geopoint*");

						if (message->from_id_){
							switch (message->from_id_->_id) {
								case id_peerUser:
									{
										tl_peerUser_t *from = 
											(tl_peerUser_t *)message->from_id_;
										d.top_message_from_peer_type = TG_PEER_TYPE_USER;	
										d.top_message_from_peer_id = from->user_id_;
									}
									break;
								case id_peerChannel:
									{
										tl_peerChannel_t *from = 
											(tl_peerChannel_t *)message->from_id_;
										d.top_message_from_peer_type = TG_PEER_TYPE_CHANNEL;	
										d.top_message_from_peer_id = from->channel_id_;
									}
									break;
								case id_peerChat:
									{
										tl_peerChat_t *from = 
											(tl_peerChat_t *)message->from_id_;
										d.top_message_from_peer_type = TG_PEER_TYPE_CHAT;	
										d.top_message_from_peer_id = from->chat_id_;
									}
									break;
								
								default:
									d.top_message_from_peer_type = TG_PEER_TYPE_NULL;	
									break;
							}
						}
						tg_message_to_database(tg, &tgm); //last msg
					}
				}
			} // done messages 

		  // save dialog to database
			tg_dialog_to_database(tg, &d);

			// update hash
			if (hash){
				ON_LOG(tg, "update_hash");
				update_hash(hash, d.top_message_id);
			}

			// callback dialog
			if (callback)
				if (callback(data, &d))
					break;

			// free dialog
			tg_dialog_free(&d);

			// counter
			n++;
		
		} // done dialogs

	} else { // not dialogs or dialogsSlice
		// throw error
		ON_ERR(tg, "%s: can't handle %s",
				__func__, TL_NAME_FROM_ID(tl->_id));
		return 0;
	}

	return n;
}

struct tg_get_dialogs_async_t {
	tg_t *tg;
	void *data;
	uint64_t *hash;
	int (*callback)(void *data, const tg_dialog_t *dialog);
	void (*on_done)(void *data);
};

void tg_get_dialogs_async_cb(void *data, const tl_t *tl)
{
	struct tg_get_dialogs_async_t *t = data;
	assert(t);
	
	if (tl == NULL){
		if (t->on_done)
			t->on_done(t->data);
		free(t);
		return;
	}

	tg_dialogs_from_tl(
			t->tg, tl, 
			t->hash, 
			t->data, t->callback);

	if (t->on_done)
		t->on_done(t->data);

	free(t);
}

pthread_t tg_get_dialogs_async(
		tg_t *tg, 
		int limit,
		time_t date, 
		uint64_t * hash, 
		uint32_t *folder_id, 
		void *data,
		int (*callback)(void *data, const tg_dialog_t *dialog),
		void (*on_done)(void *data))
{
	int i = 0, k;

	InputPeer inputPeer = tl_inputPeerSelf();

	buf_t getDialogs = 
		tl_messages_getDialogs(
				NULL,
				folder_id, 
				date,
				-1, 
				&inputPeer, 
				limit,
				hash?*hash:0);

	struct tg_get_dialogs_async_t *t = 
		NEW(struct tg_get_dialogs_async_t, 
				ON_ERR(tg, "%s: can't allocate memory", __func__);
					return 0;);
	t->tg = tg;
	t->data = data;
	t->hash = hash;
	t->callback = callback;
	t->on_done = on_done;

	pthread_t p = tg_send_query_async(
			tg, 
			&getDialogs, 
			t, tg_get_dialogs_async_cb);
	buf_free(getDialogs);
	return p;
}

int tg_get_dialogs(
		tg_t *tg, 
		int limit, 
		time_t date, 
		uint64_t * hash, 
		uint32_t *folder_id, 
		void *data,
		int (*callback)(void *data, const tg_dialog_t *dialog))
{
	int i = 0, k;

	InputPeer inputPeer = tl_inputPeerSelf();

	buf_t getDialogs = 
		tl_messages_getDialogs(
				NULL,
				folder_id, 
				date,
				-1, 
				&inputPeer, 
				limit,
				hash?*hash:0);

	tl_t *tl = tg_send_query(tg, &getDialogs);
	buf_free(getDialogs);
	if (tl == NULL){
		ON_ERR(tg, "%s: tl is NULL", __func__);
		return 0;
	}

	i = tg_dialogs_from_tl(tg, tl, hash, data, callback);

	// free tl
	tl_free(tl);

	return i;
}

int tg_get_dialogs_all(
		tg_t *tg, 
		uint64_t * hash, 
		void *data,
		int (*callback)(void *data, const tg_dialog_t *dialog))
{
	// get slice
	
	// run get dialogs
	return 0;
}



void tg_dialogs_create_table(tg_t *tg){
	// create table
	char sql[BUFSIZ]; 
	sprintf(sql, 
		"CREATE TABLE IF NOT EXISTS dialogs (id INT, peer_id INT UNIQUE);");
		ON_LOG(tg, "%s", sql);
		tg_sqlite3_exec(tg, sql);	
	
	#define TG_DIALOG_ARG(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'dialogs\' ADD COLUMN "\
				"\'" name "\' " type ";\n");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);	
	#define TG_DIALOG_STR(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'dialogs\' ADD COLUMN "\
				"\'" name "\' " type ";\n");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);	
	TG_DIALOG_ARGS
	#undef TG_DIALOG_ARG
	#undef TG_DIALOG_STR
}

int tg_dialog_to_database(tg_t *tg, const tg_dialog_t *d){
	// save dialog to database
	pthread_mutex_lock(&tg->databasem); // lock
	struct str s;
	str_init(&s);

	str_appendf(&s,
		"INSERT INTO \'dialogs\' (\'peer_id\') "
		"SELECT  "_LD_" "
		"WHERE NOT EXISTS (SELECT 1 FROM dialogs WHERE peer_id = "_LD_");\n"
		, d->peer_id, d->peer_id);

	str_appendf(&s, "UPDATE \'dialogs\' SET ");
	
	#define TG_DIALOG_STR(t, n, type, name) \
	if (d->n){\
		str_appendf(&s, "\'" name "\'" " = \'"); \
		str_append(&s, (char*)d->n, strlen((char*)d->n)); \
		str_appendf(&s, "\', "); \
	}
		
	#define TG_DIALOG_ARG(t, n, type, name) \
		str_appendf(&s, "\'" name "\'" " = "_LD_", ", (uint64_t)d->n);
	
	TG_DIALOG_ARGS
	#undef TG_DIALOG_ARG
	#undef TG_DIALOG_STR
	
	str_appendf(&s, "id = %d WHERE peer_id = "_LD_";\n"
			, tg->id, d->peer_id);
	
	/*ON_LOG(d->tg, "%s: %s", __func__, s.str);*/
	if (tg_sqlite3_exec(tg, s.str) == 0){
		// update hash
		//update_hash(&d->tg->dialogs_hash, 
								//dialog->top_message_id);
	}
	free(s.str);

	pthread_mutex_unlock(&tg->databasem); // unlock
	return 0;
}

int tg_get_dialogs_from_database(
		tg_t *tg,
		void *data,
		int (*callback)(void *data, const tg_dialog_t *dialog))
{
	ON_LOG(tg, "%s", __func__);
	//pthread_mutex_lock(&tg->databasem); // lock
	struct str s;
	str_init(&s);
	str_appendf(&s, "SELECT ");
	
	#define TG_DIALOG_ARG(t, n, type, name) \
		str_appendf(&s, name ", ");
	#define TG_DIALOG_STR(t, n, type, name) \
		str_appendf(&s, name ", ");
	TG_DIALOG_ARGS
	#undef TG_DIALOG_ARG
	#undef TG_DIALOG_STR
	
	str_appendf(&s, 
			"id FROM dialogs WHERE id = %d " 
			//"ORDER BY \'pinned\' DESC, \'top_message_date\' DESC;", tg->id);
			"ORDER BY \'top_message_date\' DESC;", tg->id);
		
	tg_sqlite3_for_each(tg, s.str, stmt){
		tg_dialog_t d;
		memset(&d, 0, sizeof(d));
		
		int col = 0;
		#define TG_DIALOG_ARG(t, n, type, name) \
			d.n = sqlite3_column_int64(stmt, col++);
		#define TG_DIALOG_STR(t, n, type, name) \
			d.n = strndup(\
				(char *)sqlite3_column_text(stmt, col),\
				sqlite3_column_bytes(stmt, col));\
			col++;
		
		TG_DIALOG_ARGS
		#undef TG_DIALOG_ARG
		#undef TG_DIALOG_STR

		if (callback){
			if (callback(data, &d)){
				tg_dialog_free(&d);
				sqlite3_close(db);
				//pthread_mutex_unlock(&tg->databasem); // unlock
				break;
			}
		}
		// free data
		tg_dialog_free(&d);
	}	
	
	//pthread_mutex_unlock(&tg->databasem); // unlock
	free(s.str);
	return 0;
}

void tg_dialog_free(tg_dialog_t *d)
{
	#define TG_DIALOG_ARG(...)
	#define TG_DIALOG_STR(t, n, ...) if(d->n) free(d->n);
	TG_DIALOG_ARGS
	#undef TG_DIALOG_ARG
	#undef TG_DIALOG_STR
}


int tg_dialog_set_top_message(
		tg_t *tg, uint64_t peer_id, uint32_t msg_id, const char *msg)
{
	// update database
	struct str str;
	str_init(&str);
	str_appendf(&str, 
			"UPDATE TABLE \'dialogs\' "
			"SET top_message_id = %d, \'top_message_text\' = ", msg_id);
	str_append(&str, msg, strlen(msg));
	str_appendf(&str,
			"WHERE \'peer_id\' = "_LD_" AND id = %d;"
			, peer_id, tg->id);
	pthread_mutex_lock(&tg->databasem); // lock
	int ret = tg_sqlite3_exec(tg, str.str);
	pthread_mutex_unlock(&tg->databasem); // unlock
	free(str.str);	
	return ret;
}

void tg_dialogs_remove_all_from_database(tg_t *tg)
{
	pthread_mutex_lock(&tg->databasem); // lock
	char sql[] = "DELETE * from \'dialogs\';";
	tg_sqlite3_exec(tg, sql);
	pthread_mutex_unlock(&tg->databasem); // unlock
}
