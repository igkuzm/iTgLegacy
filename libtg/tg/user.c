#include "user.h"
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

void tg_user_from_tl(
		tg_t *tg, tg_user_t *tgm, tl_user_t *tlm)
{
	ON_LOG(tg, "%s: start...", __func__);
	memset(tgm, 0, sizeof(tg_user_t));
	
	#define TG_USER_ARG(t, arg, ...) \
		tgm->arg = tlm->arg;
	#define TG_USER_STR(t, arg, ...) \
	if (tlm->arg.data && tlm->arg.size > 0)\
		tgm->arg = buf_strdup(tlm->arg);
	#define TG_USER_SPA(...)
	#define TG_USER_SPS(...)
	TG_USER_ARGS
	#undef TG_USER_ARG
	#undef TG_USER_STR
	#undef TG_USER_SPA
	#undef TG_USER_SPS
	
	if (tlm->photo_ && tlm->photo_->_id== id_userProfilePhoto)
	{
			tl_userProfilePhoto_t *photo = 
				(tl_userProfilePhoto_t *)tlm->photo_;
			tgm->photo_has_video = photo->has_video_;
			tgm->photo_id = photo->photo_id_; 
			tgm->photo_stripped_thumb = BUF2IMG(photo->stripped_thumb_);
			tgm->photo_dc_id = photo->dc_id_;
	}
	
	if (tlm->status_)
	{
		switch (tlm->status_->_id) {
			case id_userStatusEmpty:
				tgm->user_satus = TG_USER_STATUS_EMPTY;
				break;
			case id_userStatusOnline:
				{
					tgm->user_satus = TG_USER_STATUS_ONLINE;
					tl_userStatusOnline_t *us = 
						(tl_userStatusOnline_t *)tlm->status_;
					tgm->user_satus_time = us->expires_; 
				}
				break;
			case id_userStatusOffline:
				{
					tgm->user_satus = TG_USER_STATUS_OFFLINE;
					tl_userStatusOffline_t *us = 
						(tl_userStatusOffline_t *)tlm->status_;
					tgm->user_satus_time = us->was_online_; 
				}
				break;
			case id_userStatusLastWeek:
				{
					tgm->user_satus = TG_USER_STATUS_LASTWEEK;
					tl_userStatusLastWeek_t *us = 
						(tl_userStatusLastWeek_t *)tlm->status_;
					tgm->user_satus_byme = us->by_me_; 
				}
				break;
			case id_userStatusLastMonth:
				{
					tgm->user_satus = TG_USER_STATUS_LASTMONTH;
					tl_userStatusLastMonth_t *us = 
						(tl_userStatusLastMonth_t *)tlm->status_;
					tgm->user_satus_byme = us->by_me_; 
				}
				break;

			default:
				break;
				
		}
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

void tg_user_create_table(tg_t *tg){
	char sql[BUFSIZ]; 
	
	sprintf(sql,
		"CREATE TABLE IF NOT EXISTS users (id INT, user_id INT UNIQUE); ");
	ON_LOG(tg, "%s", sql);
	tg_sqlite3_exec(tg, sql);	
	
	#define TG_USER_ARG(t, n, type, name, ...) \
		sprintf(sql, "ALTER TABLE \'users\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);	
	#define TG_USER_STR(t, n, type, name, ...) \
		sprintf(sql, "ALTER TABLE \'users\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);	
	#define TG_USER_SPA(t, n, type, name, ...) \
		sprintf(sql, "ALTER TABLE \'users\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);
	#define TG_USER_SPS(t, n, type, name, ...) \
		sprintf(sql, "ALTER TABLE \'users\' ADD COLUMN "\
				"\'" name "\' " type ";");\
		ON_LOG(tg, "%s", sql);\
		tg_sqlite3_exec(tg, sql);
	TG_USER_ARGS
	#undef TG_USER_ARG
	#undef TG_USER_STR
	#undef TG_USER_SPA
	#undef TG_USER_SPS
} 

int tg_user_save(tg_t *tg, const tg_user_t *m)
{
	ON_LOG(tg, "%s", __func__);	
	// save chat to database
	if (pthread_mutex_lock(&tg->databasem)) // lock
	{
		ON_ERR(tg, "%s: can't lock mutex", __func__);
		return 1;
	}
	ON_LOG(tg, "%s: catched mutex!", __func__);
	struct str s;
	if (str_init(&s))
	{
		ON_LOG(tg, "%s: can't allocate memmory", __func__);
		pthread_mutex_unlock(&tg->databasem); // unlock
		return 1;
	}

	str_appendf(&s,
		"INSERT INTO \'users\' (\'user_id\') "
		"SELECT  "_LD_" "
		"WHERE NOT EXISTS (SELECT 1 FROM users WHERE user_id = "_LD_");\n"
		, m->id_, m->id_);

	str_appendf(&s, "UPDATE \'users\' SET ");
	
	#define TG_USER_STR(t, n, type, name, ifmin) \
	if (m->n && m->n[0]){\
		str_appendf(&s, "\'" name "\'" " = \'"); \
		str_append(&s, (char*)m->n, strlen((char*)m->n)); \
		str_appendf(&s, "\', "); \
	}
		
	#define TG_USER_ARG(t, n, type, name, ifmin) \
	if(m->min_ == 0 || ifmin != 1)\
		str_appendf(&s, "\'" name "\'" " = "_LD_", ", (uint64_t)m->n);
	
	#define TG_USER_SPA(t, n, type, name, ifmin) \
		str_appendf(&s, "\'" name "\'" " = "_LD_", ", (uint64_t)m->n);
	
	#define TG_USER_SPS(t, n, type, name, ifmin) \
	if (m->n && m->n[0]){\
		str_appendf(&s, "\'" name "\'" " = \'"); \
		str_append(&s, (char*)m->n, strlen((char*)m->n)); \
		str_appendf(&s, "\', "); \
	}

	TG_USER_ARGS
	#undef TG_USER_ARG
	#undef TG_USER_STR
	#undef TG_USER_SPA
	#undef TG_USER_SPS

	str_appendf(&s, "id = %d WHERE user_id = "_LD_";\n"
			, tg->id, m->id_);
	
	/*ON_LOG(d->tg, "%s: %s", __func__, s.str);*/
	int ret = tg_sqlite3_exec(tg, s.str);
	
	free(s.str);
	
	pthread_mutex_unlock(&tg->databasem); // unlock
	return ret;
}

void tg_user_free(tg_user_t *m)
{
	#define TG_USER_ARG(t, n, ...)
	#define TG_USER_STR(t, n, ...) if (m->n) free(m->n);
	#define TG_USER_SPA(t, n, ...)
	#define TG_USER_SPS(t, n, ...) if (m->n) free(m->n);
	TG_USER_ARGS
	#undef TG_USER_ARG
	#undef TG_USER_STR
	#undef TG_USER_SPA
	#undef TG_USER_SPS
}

tg_user_t * tg_user_get(tg_t *tg, uint64_t user_id)
{
	ON_LOG(tg, "%s", __func__);	
	/*pthread_mutex_lock(&tg->databasem); // lock*/
	struct str s;
	str_init(&s);
	str_appendf(&s, "SELECT ");
	
	#define TG_USER_ARG(t, n, type, name, ...) \
		str_appendf(&s, name ", ");
	#define TG_USER_STR(t, n, type, name, ...) \
		str_appendf(&s, name ", ");
	#define TG_USER_SPA(t, n, type, name, ...) \
		str_appendf(&s, name ", ");
	#define TG_USER_SPS(t, n, type, name, ...) \
		str_appendf(&s, name ", ");
	TG_USER_ARGS
	#undef TG_USER_ARG
	#undef TG_USER_STR
	#undef TG_USER_SPA
	#undef TG_USER_SPS
		
	str_appendf(&s, 
			"id FROM users WHERE id = %d AND user_id = "_LD_" "
			"ORDER BY \'date\' DESC;", tg->id, user_id);

	tg_user_t *m = NEW(tg_user_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__); return NULL;);
	
	tg_sqlite3_for_each(tg, s.str, stmt){
		
		int col = 0;
		#define TG_USER_ARG(t, n, type, name, ...) \
			m->n = sqlite3_column_int64(stmt, col++);
		#define TG_USER_STR(t, n, type, name, ...) \
			if (sqlite3_column_bytes(stmt, col) > 0){ \
				m->n = strndup(\
					(char *)sqlite3_column_text(stmt, col),\
					sqlite3_column_bytes(stmt, col));\
			}\
			col++;
		#define TG_USER_SPA(t, n, type, name, ...) \
			m->n = sqlite3_column_int64(stmt, col++);
		#define TG_USER_SPS(t, n, type, name, ...) \
			if (sqlite3_column_bytes(stmt, col) > 0){ \
				m->n = strndup(\
					(char *)sqlite3_column_text(stmt, col),\
					sqlite3_column_bytes(stmt, col));\
			}\
			col++;
		TG_USER_ARGS

		#undef TG_USER_ARG
		#undef TG_USER_STR
		#undef TG_USER_SPA
		#undef TG_USER_SPS

		break;
	}	
	/*pthread_mutex_unlock(&tg->databasem); // unlock*/
	
	free(s.str);
	return m;
}

tg_user_t * tg_user_get_by_phone(tg_t *tg, const char *phone)
{
	ON_LOG(tg, "%s", __func__);	
	/*pthread_mutex_lock(&tg->databasem); // lock*/
	struct str s;
	str_init(&s);
	str_appendf(&s, "SELECT ");
	
	#define TG_USER_ARG(t, n, type, name, ...) \
		str_appendf(&s, name ", ");
	#define TG_USER_STR(t, n, type, name, ...) \
		str_appendf(&s, name ", ");
	#define TG_USER_SPA(t, n, type, name, ...) \
		str_appendf(&s, name ", ");
	#define TG_USER_SPS(t, n, type, name, ...) \
		str_appendf(&s, name ", ");
	TG_USER_ARGS
	#undef TG_USER_ARG
	#undef TG_USER_STR
	#undef TG_USER_SPA
	#undef TG_USER_SPS
		
	str_appendf(&s, 
			"id FROM users WHERE id = %d AND phone = \'%s\'"
			"ORDER BY \'date\' DESC;", tg->id, phone);

	tg_user_t *m = NEW(tg_user_t, 
			ON_ERR(tg, "%s: can't allocate memory", __func__); return NULL;);
	
	tg_sqlite3_for_each(tg, s.str, stmt){
		
		int col = 0;
		#define TG_USER_ARG(t, n, type, name, ...) \
			m->n = sqlite3_column_int64(stmt, col++);
		#define TG_USER_STR(t, n, type, name, ...) \
			if (sqlite3_column_bytes(stmt, col) > 0){ \
				m->n = strndup(\
					(char *)sqlite3_column_text(stmt, col),\
					sqlite3_column_bytes(stmt, col));\
			}\
			col++;
		#define TG_USER_SPA(t, n, type, name, ...) \
			m->n = sqlite3_column_int64(stmt, col++);
		#define TG_USER_SPS(t, n, type, name, ...) \
			if (sqlite3_column_bytes(stmt, col) > 0){ \
				m->n = strndup(\
					(char *)sqlite3_column_text(stmt, col),\
					sqlite3_column_bytes(stmt, col));\
			}\
			col++;
		TG_USER_ARGS

		#undef TG_USER_ARG
		#undef TG_USER_STR
		#undef TG_USER_SPA
		#undef TG_USER_SPS

		break;
	}	
	
	/*pthread_mutex_unlock(&tg->databasem); // unlock*/
	free(s.str);
	return m;
}

void tg_users_save(tg_t *tg, int count, tl_t **array)
{
	ON_LOG(tg, "%s", __func__);	
	int i;
	for (i = 0; i < count; ++i) {
		if (array == NULL || 
				array[i] == NULL ||
				array[i]->_id != id_user)
			continue;

		tl_user_t *user = (tl_user_t *)array[i];
		tg_user_t tgm;	
		tg_user_from_tl(tg, &tgm, user);
		tg_user_save(tg, &tgm);
		tg_user_free(&tgm);
	}
}
