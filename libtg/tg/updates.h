#ifndef TG_UPDATES_H
#define TG_UPDATES_H
#include "tg.h"

/* When a client is being actively used, events will occur 
 * that affect the current user and that they must learn 
 * about as soon as possible, e.g. when a new message is 
 * received. To eliminate the need for the client itself 
 * to periodically download these events, there is an update 
 * delivery mechanism in which the server sends the user 
 * notifications over one of its available connections 
 * with the client.
 *
 * Update events are sent to an authorized user into the 
 * last active connection (except for connections needed 
 * for downloading / uploading files).
 *
 * So to start receiving updates the client needs to init 
 * connection and call API method, e.g. to fetch current state.*/

typedef enum {
	TG_UPDATE_NULL,
	TG_UPDATE_MESSAGE,  // data is tg_message_t
	TG_UPDATE_MESSAGE_DELETE,  // data is msg_id
	TG_UPDATE_USER_TYPING,  // data is user_id
	TG_UPDATE_USER_CANCEL,  // data is user_id
	TG_UPDATE_USER_UPLOAD_VIDEO,  // data is user_id
	TG_UPDATE_USER_UPLOAD_AUDIO,  // data is user_id
	TG_UPDATE_USER_UPLOAD_PHOTO,  // data is user_id
	TG_UPDATE_USER_UPLOAD_DOCUMENT,  // data is user_id
	TG_UPDATE_USER_RECORD_AUDIO,  // data is struct {chat_id, user_id}
	TG_UPDATE_USER_RECORD_ROUND,  // data is {chat_id, user_id}
	TG_UPDATE_CHAT_MESSAGE,      // data is {chat_id, tg_message_t}
	TG_UPDATE_CHAT_USER_TYPING,  // data is {chat_id, user_id}
	TG_UPDATE_CHAT_USER_CANCEL,  // data is {chat_id, user_id}
	TG_UPDATE_CHAT_USER_UPLOAD_VIDEO,  // data is {chat_id, user_id}
	TG_UPDATE_CHAT_USER_UPLOAD_AUDIO,  // data is {chat_id, user_id}
	TG_UPDATE_CHAT_USER_UPLOAD_PHOTO,  // data is {chat_id, user_id}
	TG_UPDATE_CHAT_USER_UPLOAD_DOCUMENT,  // data is {chat_id, user_id}
	TG_UPDATE_CHAT_USER_RECORD_AUDIO,  // data is {chat_id, user_id}
	TG_UPDATE_CHAT_USER_RECORD_ROUND,  // data is {chat_id, user_id}
	TG_UPDATE_USER_STATUS,  // data is struct {user_id, TG_USER_STATUS


} TG_UPDATE;

void tg_do_update(tg_t *tg, tl_t *update);
int tg_do_updates(tg_t *tg, tl_t *tl);

#endif /* ifndef TG_UPDATES_H */
