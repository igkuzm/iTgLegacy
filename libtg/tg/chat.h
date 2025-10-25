#ifndef TG_CHAT_T
#define TG_CHAT_T

#include <stdint.h>
#include "tg.h"
#include "peer.h"

#define TG_CHAT_ARGS\
	TG_CHAT_ARG(bool,     creator_, "INT", "creator")  \
	TG_CHAT_ARG(bool,     left_, "INT", "left")  \
	TG_CHAT_ARG(bool,     deactivated_, "INT", "deactivated")  \
	TG_CHAT_ARG(bool,     call_active_, "INT", "call_active")  \
	TG_CHAT_ARG(bool,     call_not_empty_, "INT", "call_not_empty")  \
	TG_CHAT_ARG(bool,     noforwards_, "INT", "call_not_empty")  \
	TG_CHAT_ARG(uint64_t, id_, "INT", "chat_id") \
	TG_CHAT_STR(char*,    title_, "TEXT", "title") \
	TG_CHAT_SPA(bool,     photo_has_video, "INT", "photo_has_video")  \
	TG_CHAT_SPA(uint64_t, photo_id, "INT", "photo_id") \
	TG_CHAT_SPS(char*,    photo_stripped_thumb, "TEXT", "photo_stripped_thumb") \
	TG_CHAT_SPA(uint32_t, photo_dc_id, "INT", "photo_dc_id") \
	TG_CHAT_ARG(uint32_t, participants_count_, "INT", "participants_count") \
	TG_CHAT_ARG(uint32_t, date_, "INT", "date") \
	TG_CHAT_ARG(uint32_t, version_, "INT", "version") \
	TG_CHAT_SPA(uint64_t, migrated_to_channel_id, "INT", "migrated_to_channel_id") \
	TG_CHAT_SPA(uint64_t, migrated_to_access_hash, "INT", "migrated_to_access_hash") \
	TG_CHAT_SPA(uint64_t, migrated_to_channel_access_hash, "INT", "migrated_to_channel_access_hash") \
	TG_CHAT_SPA(bool,     chat_admin_rights_change_info, "INT", "chat_admin_rights_change_info")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_post_messages, "INT", "chat_admin_rights_post_messages")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_edit_messages, "INT", "chat_admin_rights_edit_messages")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_delete_messages, "INT", "chat_admin_rights_delete_messages")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_ban_users, "INT", "chat_admin_rights_ban_users")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_invite_users, "INT", "chat_admin_rights_invite_users")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_pin_messages, "INT", "chat_admin_rights_pin_messages")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_add_admins, "INT", "chat_admin_rights_add_admins")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_anonymous, "INT", "chat_admin_rights_anonymous")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_manage_call, "INT", "chat_admin_rights_manage_call")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_other, "INT", "chat_admin_rights_other")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_manage_topics, "INT", "chat_admin_rights_manage_topics")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_post_stories, "INT", "chat_admin_rights_post_stories")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_edit_stories, "INT", "chat_admin_rights_edit_stories")  \
	TG_CHAT_SPA(bool,     chat_admin_rights_delete_stories, "INT", "chat_admin_rights_delete_stories")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_view_messages, "INT", "chat_default_banned_rights_view_messages")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_messages, "INT", "chat_default_banned_rights_send_messages")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_media, "INT", "chat_default_banned_rights_send_media")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_stickers, "INT", "chat_default_banned_rights_send_stickers")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_gifs, "INT", "chat_default_banned_rights_send_gifs")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_games, "INT", "chat_default_banned_rights_send_games")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_inline, "INT", "chat_default_banned_rights_send_inline")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_embed_links, "INT", "chat_default_banned_rights_embed_links")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_polls, "INT", "chat_default_banned_rights_send_polls")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_change_info, "INT", "chat_default_banned_rights_change_info")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_invite_users, "INT", "chat_default_banned_rights_invite_users")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_pin_messages, "INT", "chat_default_banned_rights_pin_messages")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_manage_topics, "INT", "chat_default_banned_rights_manage_topics")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_photos, "INT", "chat_default_banned_rights_send_photos")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_videos, "INT", "chat_default_banned_rights_send_videos")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_roundvideos, "INT", "chat_default_banned_rights_send_roundvideos")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_audios, "INT", "chat_default_banned_rights_send_audios")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_voices, "INT", "chat_default_banned_rights_send_voices")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_docs, "INT", "chat_default_banned_rights_send_docs")  \
	TG_CHAT_SPA(bool,     chat_default_banned_rights_send_plain, "INT", "chat_default_banned_rights_send_plain")  \
	TG_CHAT_SPA(uint32_t, chat_default_banned_rights_until_date, "INT", "chat_default_banned_rights_until_date")  \

typedef struct tg_chat_ {
	#define TG_CHAT_ARG(t, arg, ...) t arg;
	#define TG_CHAT_STR(t, arg, ...) t arg;
	#define TG_CHAT_SPA(t, arg, ...) t arg;
	#define TG_CHAT_SPS(t, arg, ...) t arg;
	TG_CHAT_ARGS
	#undef TG_CHAT_ARG
	#undef TG_CHAT_STR
	#undef TG_CHAT_SPA
	#undef TG_CHAT_SPS
} tg_chat_t;

void tg_chat_from_tl(tg_t *tg, tg_chat_t *tgm, tl_chat_t *tlm);
void tg_chat_create_table(tg_t *tg);
void tg_chat_free(tg_chat_t *c);
int tg_chat_save(tg_t *tg, const tg_chat_t *chat);
void tg_chats_save(tg_t *tg, int count, tl_t **array);
tg_chat_t * tg_chat_get(tg_t *tg, uint64_t chat_id);

void tg_chats_remove_all_from_database(tg_t *tg);
#endif /* ifndef TG_CHAT_T */
