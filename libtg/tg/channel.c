#include "channel.h"
#include "database.h"
#include "tg.h"
#include "../tl/alloc.h"
#include <assert.h>
#include <string.h>

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

void tg_channel_from_tl(
		tg_t *tg, tg_channel_t *tgm, tl_channel_t *tlm)
{
	ON_LOG(tg, "%s", __func__);
	memset(tgm, 0, sizeof(tg_channel_t));
	
	#define TG_CHANNEL_ARG(t, arg, ...) \
		tgm->arg = tlm->arg;
	#define TG_CHANNEL_STR(t, arg, ...) \
	if (tlm->arg.data && tlm->arg.size > 0)\
		tgm->arg = buf_strdup(tlm->arg);
	#define TG_CHANNEL_SPA(...)
	#define TG_CHANNEL_SPS(...)
	TG_CHANNEL_ARGS
	#undef TG_CHANNEL_ARG
	#undef TG_CHANNEL_STR
	#undef TG_CHANNEL_SPA
	#undef TG_CHANNEL_SPS
	
	if (tlm->photo_ && tlm->photo_->_id== id_chatPhoto)
	{
			tl_chatPhoto_t *photo = 
				(tl_chatPhoto_t *)tlm->photo_;
			tgm->photo_has_video = photo->has_video_;
			tgm->photo_id = photo->photo_id_; 
			tgm->photo_stripped_thumb = BUF2IMG(photo->stripped_thumb_);
			tgm->photo_dc_id = photo->dc_id_;
	}
	
	if (tlm->admin_rights_ && tlm->admin_rights_->_id== id_chatAdminRights)
	{
			tl_chatAdminRights_t *ar = 
				(tl_chatAdminRights_t *)tlm->admin_rights_;
			tgm->chat_admin_rights_change_info = ar->change_info_;
			tgm->chat_admin_rights_post_messages = ar->post_messages_;
			tgm->chat_admin_rights_edit_messages = ar->edit_messages_;
			tgm->chat_admin_rights_delete_messages = ar->delete_messages_;
			tgm->chat_admin_rights_ban_users = ar->ban_users_;
			tgm->chat_admin_rights_invite_users = ar->invite_users_;
			tgm->chat_admin_rights_pin_messages = ar->pin_messages_;
			tgm->chat_admin_rights_add_admins = ar->add_admins_;
			tgm->chat_admin_rights_anonymous = ar->anonymous_;
			tgm->chat_admin_rights_manage_call = ar->manage_call_;
			tgm->chat_admin_rights_other = ar->other_;
			tgm->chat_admin_rights_manage_topics = ar->manage_topics_;
			tgm->chat_admin_rights_post_stories = ar->post_stories_;
			tgm->chat_admin_rights_edit_stories = ar->edit_stories_;
			tgm->chat_admin_rights_delete_stories = ar->delete_stories_;
	}


	if (tlm->default_banned_rights_ && 
			tlm->default_banned_rights_->_id== id_chatBannedRights)
	{
			tl_chatBannedRights_t *br = 
				(tl_chatBannedRights_t *)tlm->default_banned_rights_;
		tgm->chat_default_banned_rights_view_messages = br->view_messages_;
		tgm->chat_default_banned_rights_send_messages = br->send_messages_;
		tgm->chat_default_banned_rights_send_media = br->send_media_;
		tgm->chat_default_banned_rights_send_stickers = br->send_stickers_;
		tgm->chat_default_banned_rights_send_gifs = br->send_gifs_;
		tgm->chat_default_banned_rights_send_games = br->send_games_;
		tgm->chat_default_banned_rights_send_inline = br->send_inline_;
		tgm->chat_default_banned_rights_embed_links = br->embed_links_;
		tgm->chat_default_banned_rights_send_polls = br->send_polls_;
		tgm->chat_default_banned_rights_change_info = br->change_info_;
		tgm->chat_default_banned_rights_invite_users = br->invite_users_;
		tgm->chat_default_banned_rights_pin_messages = br->pin_messages_;
		tgm->chat_default_banned_rights_manage_topics = br->manage_topics_;
		tgm->chat_default_banned_rights_send_photos = br->send_photos_;
		tgm->chat_default_banned_rights_send_videos = br->send_videos_;
		tgm->chat_default_banned_rights_send_roundvideos = br->send_roundvideos_;
		tgm->chat_default_banned_rights_send_audios = br->send_audios_;
		tgm->chat_default_banned_rights_send_voices = br->send_voices_;
		tgm->chat_default_banned_rights_send_docs = br->send_docs_;
		tgm->chat_default_banned_rights_send_plain = br->send_plain_;
		tgm->chat_default_banned_rights_until_date = br->until_date_;
	}

	if (tlm->color_ && 
			tlm->color_->_id== id_peerColor)
	{
		tl_peerColor_t *color = (tl_peerColor_t *)tlm->color_;
		tgm->color = color->color_;
	}	
	if (tlm->profile_color_ && 
			tlm->profile_color_->_id== id_peerColor)
	{
		tl_peerColor_t *color = (tl_peerColor_t *)tlm->profile_color_;
		tgm->profile_color = color->color_;
	}	
}

void tg_channel_create_table(tg_t *tg){
	ON_LOG(tg, "%s", __func__);	
	char sql[BUFSIZ]; 
	
	sprintf(sql,
		"CREATE TABLE IF NOT EXISTS channels (id INT, channel_id INT UNIQUE); ");
	ON_LOG(tg, "%s", sql);
	tg_sqlite3_exec(tg, sql);	
	
	#define TG_CHANNEL_ARG(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'channels\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);	
	#define TG_CHANNEL_STR(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'channels\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);	
	#define TG_CHANNEL_SPA(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'channels\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);
	#define TG_CHANNEL_SPS(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'channels\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);
	TG_CHANNEL_ARGS
	#undef TG_CHANNEL_ARG
	#undef TG_CHANNEL_STR
	#undef TG_CHANNEL_SPA
	#undef TG_CHANNEL_SPS
} 

int tg_channel_save(tg_t *tg, const tg_channel_t *m)
{
	ON_LOG(tg, "%s", __func__);	
	// save chat to database
	pthread_mutex_lock(&tg->databasem); // lock
	struct str s;
	str_init(&s);

	str_appendf(&s,
		"INSERT INTO \'channels\' (\'channel_id\') "
		"SELECT  "_LD_" "
		"WHERE NOT EXISTS (SELECT 1 FROM channels WHERE channel_id = "_LD_");\n"
		, m->id_, m->id_);

	str_appendf(&s, "UPDATE \'channels\' SET ");
	
	#define TG_CHANNEL_STR(t, n, type, name) \
	if (m->n && m->n[0]){\
		str_appendf(&s, "\'" name "\'" " = \'"); \
		str_append(&s, (char*)m->n, strlen((char*)m->n)); \
		str_appendf(&s, "\', "); \
	}
		
	#define TG_CHANNEL_ARG(t, n, type, name) \
		str_appendf(&s, "\'" name "\'" " = "_LD_", ", (uint64_t)m->n);
	
	#define TG_CHANNEL_SPA(t, n, type, name) \
		str_appendf(&s, "\'" name "\'" " = "_LD_", ", (uint64_t)m->n);
	
	#define TG_CHANNEL_SPS(t, n, type, name) \
	if (m->n && m->n[0]){\
		str_appendf(&s, "\'" name "\'" " = \'"); \
		str_append(&s, (char*)m->n, strlen((char*)m->n)); \
		str_appendf(&s, "\', "); \
	}

	TG_CHANNEL_ARGS
	#undef TG_CHANNEL_ARG
	#undef TG_CHANNEL_STR
	#undef TG_CHANNEL_SPA
	#undef TG_CHANNEL_SPS

	str_appendf(&s, "id = %d WHERE channel_id = "_LD_";\n"
			, tg->id, m->id_);
	
	/*ON_LOG(d->tg, "%s: %s", __func__, s.str);*/
	int ret = tg_sqlite3_exec(tg, s.str);
	
	free(s.str);
	
	pthread_mutex_unlock(&tg->databasem); // unlock
	return ret;
}

void tg_channel_free(tg_channel_t *m)
{
	#define TG_CHANNEL_ARG(t, n, ...)
	#define TG_CHANNEL_STR(t, n, ...) if (m->n) free(m->n);
	#define TG_CHANNEL_SPA(t, n, ...)
	#define TG_CHANNEL_SPS(t, n, ...) if (m->n) free(m->n);
	TG_CHANNEL_ARGS
	#undef TG_CHANNEL_ARG
	#undef TG_CHANNEL_STR
	#undef TG_CHANNEL_SPA
	#undef TG_CHANNEL_SPS
}

tg_channel_t * tg_channel_get(tg_t *tg, uint64_t channel_id)
{
	ON_LOG(tg, "%s", __func__);	
	//pthread_mutex_lock(&tg->databasem); // lock
	struct str s;
	str_init(&s);
	str_appendf(&s, "SELECT ");
	
	#define TG_CHANNEL_ARG(t, n, type, name) \
		str_appendf(&s, name ", ");
	#define TG_CHANNEL_STR(t, n, type, name) \
		str_appendf(&s, name ", ");
	#define TG_CHANNEL_SPA(t, n, type, name) \
		str_appendf(&s, name ", ");
	#define TG_CHANNEL_SPS(t, n, type, name) \
		str_appendf(&s, name ", ");
	TG_CHANNEL_ARGS
	#undef TG_CHANNEL_ARG
	#undef TG_CHANNEL_STR
	#undef TG_CHANNEL_SPA
	#undef TG_CHANNEL_SPS
		
	str_appendf(&s, 
			"id FROM channels WHERE id = %d AND channel_id = "_LD_" "
			"ORDER BY \'date\' DESC;", tg->id, channel_id);

	tg_channel_t *m = NEW(tg_channel_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__); return NULL;);
	
	tg_sqlite3_for_each(tg, s.str, stmt){
		
		int col = 0;
		#define TG_CHANNEL_ARG(t, n, type, name) \
			m->n = sqlite3_column_int64(stmt, col++);
		#define TG_CHANNEL_STR(t, n, type, name) \
			if (sqlite3_column_bytes(stmt, col) > 0){ \
				m->n = strndup(\
					(char *)sqlite3_column_text(stmt, col),\
					sqlite3_column_bytes(stmt, col));\
			}\
			col++;
		#define TG_CHANNEL_SPA(t, n, type, name) \
			m->n = sqlite3_column_int64(stmt, col++);
		#define TG_CHANNEL_SPS(t, n, type, name) \
			if (sqlite3_column_bytes(stmt, col) > 0){ \
				m->n = strndup(\
					(char *)sqlite3_column_text(stmt, col),\
					sqlite3_column_bytes(stmt, col));\
			}\
			col++;
		TG_CHANNEL_ARGS

		#undef TG_CHANNEL_ARG
		#undef TG_CHANNEL_STR
		#undef TG_CHANNEL_SPA
		#undef TG_CHANNEL_SPS

		break;
	}	
	
	//pthread_mutex_unlock(&tg->databasem); // unlock
	free(s.str);
	return m;
}

int tg_parse_chennels(tg_t *tg, int argc, tl_t **argv,
	void *data,
	int (*callback)(void *data, const tg_channel_t *cannel))
{
	int i, n = 0;
	for (i = 0; i < argc; ++i) {
		if (argv[i]->_id == id_channel)
		{
			tl_channel_t *channel = 
				(tl_channel_t *)argv[i];

			tg_channel_t tgm;
			tg_channel_from_tl(tg, &tgm, channel);
			if (callback){
				if (callback(data, &tgm)){
					tg_channel_free(&tgm);
					return ++n;
				}
			}
			tg_channel_free(&tgm);
			n++;
		}
	}
	return n;
}

struct tg_channel_search_global_t {
	tg_t *tg;
	void *data;
	int (*callback)(void *data, const tg_channel_t *cannel);
	void (*on_done)(void *data);
};

void tg_channel_search_global_cb(void *d, const tl_t *tl)
{
	assert(d);
	struct tg_channel_search_global_t *t = d;
	if (tl == NULL){
		if (t->on_done)
			t->on_done(t->data);
		free(t);
		return;
	}

	switch (tl->_id) {
		case id_messages_channelMessages:
			{
				tl_messages_channelMessages_t *msgs = 
					(tl_messages_channelMessages_t *)tl;
				tg_parse_chennels(t->tg, 
						msgs->chats_len, 
						msgs->chats_, 
						t->data, 
						t->callback);
			}
			break;
			
		case id_messages_messages:
			{
				tl_messages_messages_t *msgs = 
					(tl_messages_messages_t *)tl;
				
				tg_parse_chennels(t->tg, 
						msgs->chats_len, 
						msgs->chats_, 
						t->data, 
						t->callback);
			}
			break;
			
		case id_messages_messagesSlice:
			{
				tl_messages_messagesSlice_t *msgs = 
					(tl_messages_messagesSlice_t *)tl;
					
				tg_parse_chennels(t->tg, 
						msgs->chats_len, 
						msgs->chats_, 
						t->data, 
						t->callback);
			}
			break;
			
		default:
			break;
	}

	if (t->on_done)
		t->on_done(t->data);
	free(t);
}

int tg_channel_search_global(tg_t *tg, const char *query, 
		MessagesFilter *filter, 
		int offset, int limit, 
		void *data, 
		int (*callback)(void *data, const tg_channel_t *cannel))
{
	InputPeer inputPeer = tl_inputPeerEmpty();
	buf_t search = tl_messages_searchGlobal(
			true, 
			NULL, 
			query, 
			filter, 
			0, 
			0, 
			0, 
			&inputPeer, 
			offset, 
			limit);
	buf_free(inputPeer);

	tl_t *tl = tg_send_query(tg, &search);
	buf_free(search);

	if (tl == NULL)
		return 0;

	int n = 0;

	switch (tl->_id) {
		case id_messages_channelMessages:
			{
				tl_messages_channelMessages_t *msgs = 
					(tl_messages_channelMessages_t *)tl;
				n = tg_parse_chennels(tg, 
						msgs->chats_len, 
						msgs->chats_, 
						data, 
						callback);
			}
			break;
			
		case id_messages_messages:
			{
				tl_messages_messages_t *msgs = 
					(tl_messages_messages_t *)tl;

				n = tg_parse_chennels(tg, 
						msgs->chats_len, 
						msgs->chats_, 
						data, 
						callback);
			}
			break;
			
		case id_messages_messagesSlice:
			{
				tl_messages_messagesSlice_t *msgs = 
					(tl_messages_messagesSlice_t *)tl;
					
				n = tg_parse_chennels(tg, 
						msgs->chats_len, 
						msgs->chats_, 
						data, 
						callback);
			}
			break;
			
		default:
			break;
	}

	return n;
}

int tg_channel_set_read(tg_t *tg, tg_peer_t peer, uint32_t max_id)
{
	InputChannel inputChannel = tl_inputChannel(
			peer.id, peer.access_hash);

	buf_t query = tl_channels_readHistory(
			&inputChannel, max_id);
	buf_free(inputChannel);
	
	tg_send_query(
			tg, &query);
	buf_free(query);
	
	return 0;
}

