#ifndef TG_USER_T
#define TG_USER_T

#include <stdint.h>
#include "tg.h"
#include "peer.h"

typedef enum {
	TG_USER_STATUS_EMPTY     = id_userStatusEmpty,
	TG_USER_STATUS_ONLINE    = id_userStatusOnline,
	TG_USER_STATUS_OFFLINE   = id_userStatusOffline,
	TG_USER_STATUS_RECENTLY  = id_userStatusRecently,
	TG_USER_STATUS_LASTWEEK  = id_userStatusLastWeek,
	TG_USER_STATUS_LASTMONTH = id_userStatusLastMonth,
} TG_USER_STATUS;

#define TG_USER_ARGS\
	TG_USER_ARG(bool,     self_, "INT", "self", 0)  \
	TG_USER_ARG(bool,     contact_, "INT", "contact", 1)  \
	TG_USER_ARG(bool,     mutual_contact_, "INT", "mutual_contact", 1)  \
	TG_USER_ARG(bool,     deleted_, "INT", "deleted", 0)  \
	TG_USER_ARG(bool,     bot_, "INT", "bot", 0)  \
	TG_USER_ARG(bool,     bot_chat_history_, "INT", "bot_chat_history", 0)  \
	TG_USER_ARG(bool,     bot_nochats_, "INT", "bot_nochats", 0)  \
	TG_USER_ARG(bool,     verified_, "INT", "verified", 0)  \
	TG_USER_ARG(bool,     restricted_, "INT", "restricted", 0)  \
	TG_USER_ARG(bool,     min_, "INT", "min", 0)  \
	TG_USER_ARG(bool,     bot_inline_geo_, "INT", "bot_inline_geo", 0)  \
	TG_USER_ARG(bool,     support_, "INT", "support", 0)  \
	TG_USER_ARG(bool,     scam_, "INT", "scam", 0)  \
	TG_USER_ARG(bool,     apply_min_photo_, "INT", "apply_min_photo", 0)  \
	TG_USER_ARG(bool,     fake_, "INT", "fake", 0)  \
	TG_USER_ARG(bool,     bot_attach_menu_, "INT", "bot_attach_menu", 0)  \
	TG_USER_ARG(bool,     premium_, "INT", "premium", 0)  \
	TG_USER_ARG(bool,     attach_menu_enabled_, "INT", "attach_menu_enabled", 0)  \
	TG_USER_ARG(bool,     bot_can_edit_, "INT", "bot_can_edit", 0)  \
	TG_USER_ARG(bool,     close_friend_, "INT", "close_friend", 1)  \
	TG_USER_ARG(bool,     stories_hidden_, "INT", "stories_hidden", 1)  \
	TG_USER_ARG(bool,     stories_unavailable_, "INT", "stories_unavailable", 0)  \
	TG_USER_ARG(bool,     contact_require_premium_, "INT", "contact_require_premium", 0)  \
	TG_USER_ARG(bool,     bot_business_, "INT", "bot_business", 0)  \
	TG_USER_ARG(bool,     bot_has_main_app_, "INT", "bot_has_main_app", 0)  \
	TG_USER_ARG(uint64_t, id_, "INT", "user_id", 0)  \
	TG_USER_ARG(uint64_t, access_hash_, "INT", "access_hash", 2)  \
	TG_USER_STR(char*,    first_name_, "TEXT", "first_name", 2) \
	TG_USER_STR(char*,    last_name_, "TEXT", "last_name", 2) \
	TG_USER_STR(char*,    username_, "TEXT", "username", 2) \
	TG_USER_STR(char*,    phone_, "TEXT", "phone", 2) \
	TG_USER_SPA(bool,     photo_has_video, "INT", "photo_has_video", 2)  \
	TG_USER_SPA(bool,     photo_personal, "INT", "photo_personal", 2)  \
	TG_USER_SPA(uint64_t, photo_id, "INT", "photo_id", 2)  \
	TG_USER_SPS(char*,    photo_stripped_thumb, "INT", "photo_stripped_thumb", 2)  \
	TG_USER_SPA(uint32_t, photo_dc_id, "INT", "photo_dc_id", 2)  \
	TG_USER_SPA(uint32_t, user_satus, "INT", "user_status", 2)  \
	TG_USER_SPA(uint32_t, user_satus_time, "INT", "user_status_time", 2)  \
	TG_USER_SPA(bool,     user_satus_byme, "INT", "user_status_byme", 2)  \
	TG_USER_ARG(bool,     bot_info_version_, "INT", "bot_info_version", 0)  \
	TG_USER_STR(char*,    bot_inline_placeholder_, "INT", "bot_inline_placeholder", 0)  \
	TG_USER_STR(char*,    lang_code_, "INT", "lang_code", 0)  \
	TG_USER_ARG(bool,     stories_max_id_, "INT", "stories_max_id", 1)  \
	TG_USER_SPA(uint32_t, color, "INT", "color", 0)  \
	TG_USER_SPA(uint32_t, profile_color, "INT", "profile_color", 0)  \
	TG_USER_ARG(uint32_t, bot_active_users_, "INT", "bot_active_users", 0)  \
	
typedef struct tg_user_ {
	#define TG_USER_ARG(t, arg, ...) t arg;
	#define TG_USER_STR(t, arg, ...) t arg;
	#define TG_USER_SPA(t, arg, ...) t arg;
	#define TG_USER_SPS(t, arg, ...) t arg;
	TG_USER_ARGS
	#undef TG_USER_ARG
	#undef TG_USER_STR
	#undef TG_USER_SPA
	#undef TG_USER_SPS
} tg_user_t;

void tg_user_from_tl(tg_t *tg, tg_user_t *tgm, tl_user_t *tlm);
void tg_user_create_table(tg_t *tg);
void tg_user_free(tg_user_t *c);
int tg_user_save(tg_t *tg, const tg_user_t *user);
void tg_users_save(tg_t *tg, int count, tl_t **array);
tg_user_t * tg_user_get(tg_t *tg, uint64_t user_id);
tg_user_t * tg_user_get_by_phone(tg_t *tg, const char *phone);

#endif /* ifndef TG_USER_T */
