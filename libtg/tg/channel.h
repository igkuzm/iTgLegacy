#ifndef TG_CHANNEL_H
#define TG_CHANNEL_H

#include "tg.h"
#include "peer.h"

#define TG_CHANNEL_ARGS\
	TG_CHANNEL_ARG(bool,     creator_, "INT", "creator")  \
	TG_CHANNEL_ARG(bool,     left_, "INT", "left")  \
	TG_CHANNEL_ARG(bool,     broadcast_, "INT", "broadcast")  \
	TG_CHANNEL_ARG(bool,     verified_, "INT", "verified")  \
	TG_CHANNEL_ARG(bool,     megagroup_, "INT", "megagroup")  \
	TG_CHANNEL_ARG(bool,     restricted_, "INT", "restricted")  \
	TG_CHANNEL_ARG(bool,     signatures_, "INT", "signatures")  \
	TG_CHANNEL_ARG(bool,     min_, "INT", "min")  \
	TG_CHANNEL_ARG(bool,     scam_, "INT", "scam")  \
	TG_CHANNEL_ARG(bool,     has_link_, "INT", "has_link")  \
	TG_CHANNEL_ARG(bool,     has_geo_, "INT", "has_geo")  \
	TG_CHANNEL_ARG(bool,     slowmode_enabled_, "INT", "slowmode_enabled")  \
	TG_CHANNEL_ARG(bool,     call_active_, "INT", "call_active")  \
	TG_CHANNEL_ARG(bool,     call_not_empty_, "INT", "call_not_empty")  \
	TG_CHANNEL_ARG(bool,     fake_, "INT", "fake")  \
	TG_CHANNEL_ARG(bool,     gigagroup_, "INT", "gigagroup")  \
	TG_CHANNEL_ARG(bool,     noforwards_, "INT", "noforwards")  \
	TG_CHANNEL_ARG(bool,     join_to_send_, "INT", "join_to_send")  \
	TG_CHANNEL_ARG(bool,     join_request_, "INT", "join_request")  \
	TG_CHANNEL_ARG(bool,     forum_, "INT", "forum")  \
	TG_CHANNEL_ARG(bool,     stories_hidden_, "INT", "stories_hidden")  \
	TG_CHANNEL_ARG(bool,     stories_hidden_min_, "INT", "stories_hidden_min")  \
	TG_CHANNEL_ARG(bool,     stories_unavailable_, "INT", "stories_unavailable")  \
	TG_CHANNEL_ARG(uint64_t, id_, "INT", "channel_id") \
	TG_CHANNEL_ARG(uint64_t, access_hash_, "INT", "access_hash") \
	TG_CHANNEL_STR(char*,    title_, "TEXT", "title") \
	TG_CHANNEL_STR(char*,    username_, "TEXT", "username") \
	TG_CHANNEL_SPA(bool,     photo_has_video, "INT", "photo_has_video")  \
	TG_CHANNEL_SPA(uint64_t, photo_id, "INT", "photo_id") \
	TG_CHANNEL_SPS(char*,    photo_stripped_thumb, "TEXT", "photo_stripped_thumb") \
	TG_CHANNEL_SPA(uint32_t, photo_dc_id, "INT", "photo_dc_id") \
	TG_CHANNEL_ARG(uint32_t, date_, "INT", "date") \
	TG_CHANNEL_ARG(uint32_t, participants_count_, "INT", "participants_count") \
	TG_CHANNEL_ARG(uint32_t, stories_max_id_, "INT", "stories_max_id") \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_change_info, "INT", "chat_admin_rights_change_info")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_post_messages, "INT", "chat_admin_rights_post_messages")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_edit_messages, "INT", "chat_admin_rights_edit_messages")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_delete_messages, "INT", "chat_admin_rights_delete_messages")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_ban_users, "INT", "chat_admin_rights_ban_users")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_invite_users, "INT", "chat_admin_rights_invite_users")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_pin_messages, "INT", "chat_admin_rights_pin_messages")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_add_admins, "INT", "chat_admin_rights_add_admins")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_anonymous, "INT", "chat_admin_rights_anonymous")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_manage_call, "INT", "chat_admin_rights_manage_call")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_other, "INT", "chat_admin_rights_other")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_manage_topics, "INT", "chat_admin_rights_manage_topics")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_post_stories, "INT", "chat_admin_rights_post_stories")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_edit_stories, "INT", "chat_admin_rights_edit_stories")  \
	TG_CHANNEL_SPA(bool,     chat_admin_rights_delete_stories, "INT", "chat_admin_rights_delete_stories")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_view_messages, "INT", "chat_default_banned_rights_view_messages")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_messages, "INT", "chat_default_banned_rights_send_messages")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_media, "INT", "chat_default_banned_rights_send_media")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_stickers, "INT", "chat_default_banned_rights_send_stickers")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_gifs, "INT", "chat_default_banned_rights_send_gifs")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_games, "INT", "chat_default_banned_rights_send_games")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_inline, "INT", "chat_default_banned_rights_send_inline")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_embed_links, "INT", "chat_default_banned_rights_embed_links")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_polls, "INT", "chat_default_banned_rights_send_polls")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_change_info, "INT", "chat_default_banned_rights_change_info")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_invite_users, "INT", "chat_default_banned_rights_invite_users")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_pin_messages, "INT", "chat_default_banned_rights_pin_messages")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_manage_topics, "INT", "chat_default_banned_rights_manage_topics")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_photos, "INT", "chat_default_banned_rights_send_photos")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_videos, "INT", "chat_default_banned_rights_send_videos")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_roundvideos, "INT", "chat_default_banned_rights_send_roundvideos")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_audios, "INT", "chat_default_banned_rights_send_audios")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_voices, "INT", "chat_default_banned_rights_send_voices")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_docs, "INT", "chat_default_banned_rights_send_docs")  \
	TG_CHANNEL_SPA(bool,     chat_default_banned_rights_send_plain, "INT", "chat_default_banned_rights_send_plain")  \
	TG_CHANNEL_SPA(uint32_t, chat_default_banned_rights_until_date, "INT", "chat_default_banned_rights_until_date")  \
	TG_CHANNEL_SPA(uint32_t, color, "INT", "color")  \
	TG_CHANNEL_SPA(uint32_t, profile_color, "INT", "profile_color")  \

typedef struct tg_channel_ {
	#define TG_CHANNEL_ARG(t, arg, ...) t arg;
	#define TG_CHANNEL_STR(t, arg, ...) t arg;
	#define TG_CHANNEL_SPA(t, arg, ...) t arg;
	#define TG_CHANNEL_SPS(t, arg, ...) t arg;
	TG_CHANNEL_ARGS
	#undef TG_CHANNEL_ARG
	#undef TG_CHANNEL_STR
	#undef TG_CHANNEL_SPA
	#undef TG_CHANNEL_SPS
} tg_channel_t;

void tg_channel_from_tl(tg_t *tg, tg_channel_t *tgm, tl_channel_t *tlm);
void tg_channel_create_table(tg_t *tg);
void tg_channel_free(tg_channel_t *c);
int tg_channel_save(tg_t *tg, const tg_channel_t *channel);
tg_channel_t * tg_channel_get(tg_t *tg, uint64_t chat_id);

int tg_channel_search_global(tg_t *tg, const char *query, 
		MessagesFilter *filter, 
		int offset, int limit, 
		void *data, 
		int (*callback)(void *data, const tg_channel_t *cannel));

int tg_channel_set_read(tg_t *tg, tg_peer_t peer, uint32_t max_id);

#endif /* ifndef TG_CHANNEL_H */
