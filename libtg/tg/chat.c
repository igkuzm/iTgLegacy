#include "chat.h"
#include "channel.h"
#include "database.h"
#include "tg.h"
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

#define BUF2STR(_b) strndup((char*)_b.data, _b.size)
#define BUF2IMG(_b) \
	({buf_t i = image_from_photo_stripped(_b); \
	 buf_to_base64(i);}) 

void tg_chat_from_tl(
		tg_t *tg, tg_chat_t *tgm, tl_chat_t *tlm)
{
	ON_LOG(tg, "%s", __func__);
	memset(tgm, 0, sizeof(tg_chat_t));
	
	#define TG_CHAT_ARG(t, arg, ...) \
		tgm->arg = tlm->arg;
	#define TG_CHAT_STR(t, arg, ...) \
	if (tlm->arg.data && tlm->arg.size > 0)\
		tgm->arg = buf_strdup(tlm->arg);
	#define TG_CHAT_SPA(...)
	#define TG_CHAT_SPS(...)
	TG_CHAT_ARGS
	#undef TG_CHAT_ARG
	#undef TG_CHAT_STR
	#undef TG_CHAT_SPA
	#undef TG_CHAT_SPS
	
	if (tlm->migrated_to_)
	{
		if (tlm->migrated_to_->_id == id_inputChannel){
			tl_inputChannel_t *ic = 
				(tl_inputChannel_t *)tlm->migrated_to_;
			tgm->migrated_to_channel_id = ic->channel_id_;
			tgm->migrated_to_access_hash = ic->access_hash_;
		} else if (tlm->migrated_to_->_id == id_inputChannelFromMessage){
			tl_inputChannelFromMessage_t *ic = 
				(tl_inputChannelFromMessage_t *)tlm->migrated_to_;
			tgm->migrated_to_channel_id = ic->channel_id_;
		}
	}
	
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
}

void tg_chat_create_table(tg_t *tg){
	char sql[BUFSIZ]; 
	
	sprintf(sql,
		"CREATE TABLE IF NOT EXISTS chats (id INT, chat_id INT UNIQUE); ");
	ON_LOG(tg, "%s", sql);
	tg_sqlite3_exec(tg, sql);	
	
	#define TG_CHAT_ARG(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'chats\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);	
	#define TG_CHAT_STR(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'chats\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);	
	#define TG_CHAT_SPA(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'chats\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);
	#define TG_CHAT_SPS(t, n, type, name) \
		sprintf(sql, "ALTER TABLE \'chats\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);
	TG_CHAT_ARGS
	#undef TG_CHAT_ARG
	#undef TG_CHAT_STR
	#undef TG_CHAT_SPA
	#undef TG_CHAT_SPS
} 

int tg_chat_save(tg_t *tg, const tg_chat_t *m)
{
	ON_LOG(tg, "%s", __func__);	
	// save chat to database
	pthread_mutex_lock(&tg->databasem); // lock
	struct str s;
	str_init(&s);

	str_appendf(&s,
		"INSERT INTO \'chats\' (\'chat_id\') "
		"SELECT  "_LD_" "
		"WHERE NOT EXISTS (SELECT 1 FROM chats WHERE chat_id = "_LD_");\n"
		, m->id_, m->id_);

	str_appendf(&s, "UPDATE \'chats\' SET ");
	
	#define TG_CHAT_STR(t, n, type, name) \
	if (m->n && m->n[0]){\
		str_appendf(&s, "\'" name "\'" " = \'"); \
		str_append(&s, (char*)m->n, strlen((char*)m->n)); \
		str_appendf(&s, "\', "); \
	}
		
	#define TG_CHAT_ARG(t, n, type, name) \
		str_appendf(&s, "\'" name "\'" " = "_LD_", ", (uint64_t)m->n);
	
	#define TG_CHAT_SPA(t, n, type, name) \
		str_appendf(&s, "\'" name "\'" " = "_LD_", ", (uint64_t)m->n);
	
	#define TG_CHAT_SPS(t, n, type, name) \
	if (m->n && m->n[0]){\
		str_appendf(&s, "\'" name "\'" " = \'"); \
		str_append(&s, (char*)m->n, strlen((char*)m->n)); \
		str_appendf(&s, "\', "); \
	}

	TG_CHAT_ARGS
	#undef TG_CHAT_ARG
	#undef TG_CHAT_STR
	#undef TG_CHAT_SPA
	#undef TG_CHAT_SPS

	str_appendf(&s, "id = %d WHERE chat_id = "_LD_";\n"
			, tg->id, m->id_);
	
	/*ON_LOG(d->tg, "%s: %s", __func__, s.str);*/
	int ret = tg_sqlite3_exec(tg, s.str);
	
	free(s.str);
	
	pthread_mutex_unlock(&tg->databasem); // unlock
	return ret;
}

void tg_chat_free(tg_chat_t *m)
{
	#define TG_CHAT_ARG(t, n, ...)
	#define TG_CHAT_STR(t, n, ...) if (m->n) free(m->n);
	#define TG_CHAT_SPA(t, n, ...)
	#define TG_CHAT_SPS(t, n, ...) if (m->n) free(m->n);
	TG_CHAT_ARGS
	#undef TG_CHAT_ARG
	#undef TG_CHAT_STR
	#undef TG_CHAT_SPA
	#undef TG_CHAT_SPS
}

tg_chat_t * tg_chat_get(tg_t *tg, uint64_t chat_id)
{
	ON_LOG(tg, "%s", __func__);	
	/*pthread_mutex_lock(&tg->databasem); // lock*/
	struct str s;
	str_init(&s);
	str_appendf(&s, "SELECT ");
	
	#define TG_CHAT_ARG(t, n, type, name) \
		str_appendf(&s, name ", ");
	#define TG_CHAT_STR(t, n, type, name) \
		str_appendf(&s, name ", ");
	#define TG_CHAT_SPA(t, n, type, name) \
		str_appendf(&s, name ", ");
	#define TG_CHAT_SPS(t, n, type, name) \
		str_appendf(&s, name ", ");
	TG_CHAT_ARGS
	#undef TG_CHAT_ARG
	#undef TG_CHAT_STR
	#undef TG_CHAT_SPA
	#undef TG_CHAT_SPS
		
	str_appendf(&s, 
			"id FROM chats WHERE id = %d AND chat_id = "_LD_" "
			"ORDER BY \'date\' DESC;", tg->id, chat_id);

	tg_chat_t *m = NEW(tg_chat_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__); return NULL;);
	
	tg_sqlite3_for_each(tg, s.str, stmt){
		
		int col = 0;
		#define TG_CHAT_ARG(t, n, type, name) \
			m->n = sqlite3_column_int64(stmt, col++);
		#define TG_CHAT_STR(t, n, type, name) \
			if (sqlite3_column_bytes(stmt, col) > 0){ \
				m->n = strndup(\
					(char *)sqlite3_column_text(stmt, col),\
					sqlite3_column_bytes(stmt, col));\
			}\
			col++;
		#define TG_CHAT_SPA(t, n, type, name) \
			m->n = sqlite3_column_int64(stmt, col++);
		#define TG_CHAT_SPS(t, n, type, name) \
			if (sqlite3_column_bytes(stmt, col) > 0){ \
				m->n = strndup(\
					(char *)sqlite3_column_text(stmt, col),\
					sqlite3_column_bytes(stmt, col));\
			}\
			col++;
		TG_CHAT_ARGS

		#undef TG_CHAT_ARG
		#undef TG_CHAT_STR
		#undef TG_CHAT_SPA
		#undef TG_CHAT_SPS

		break;
	}	
	
	/*pthread_mutex_unlock(&tg->databasem); // unlock*/
	free(s.str);
	return m;
}

void tg_chats_save(tg_t *tg, int count, tl_t **array)
{
	ON_LOG(tg, "%s", __func__);	
	int i;
	for (i = 0; i < count; ++i) {
		if (array == NULL || 
				array[i] == NULL ||
				(array[i]->_id != id_chat && 
				 array[i]->_id != id_channel))
			continue;

		if (array[i]->_id == id_chat){
			tl_chat_t *c = (tl_chat_t *)array[i];
			tg_chat_t tgm;	
			tg_chat_from_tl(tg, &tgm, c);
			tg_chat_save(tg, &tgm);
			tg_chat_free(&tgm);
		} else if (array[i]->_id == id_channel){
			tl_channel_t *c = (tl_channel_t *)array[i];
			tg_channel_t tgm;	
			tg_channel_from_tl(tg, &tgm, c);
			tg_channel_save(tg, &tgm);
			tg_channel_free(&tgm);
		}
	}
}
