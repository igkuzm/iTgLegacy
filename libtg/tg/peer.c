#include "peer.h"
#include "tg.h"
#include <stdint.h>

buf_t tg_inputPeer(tg_peer_t peer)
{
	buf_t p;
	switch (peer.type) {
		case TG_PEER_TYPE_CHANNEL:
			p = tl_inputPeerChannel(
					peer.id, peer.access_hash);
			break;
		case TG_PEER_TYPE_CHAT:
			p = tl_inputPeerChat(peer.id);
			break;
		case TG_PEER_TYPE_USER:
			p = tl_inputPeerUser(
					peer.id, peer.access_hash);
			break;
		default:
			buf_init(&p);
			break;
	}
	return p;
}

buf_t tg_peer(tg_peer_t peer)
{
	buf_t p;
	switch (peer.type) {
		case TG_PEER_TYPE_CHANNEL:
			p = tl_peerChannel(peer.id);
			break;
		case TG_PEER_TYPE_CHAT:
			p = tl_peerChat(peer.id);
			break;
		case TG_PEER_TYPE_USER:
			p = tl_peerUser(peer.id);
			break;
		default:
			buf_init(&p);
			break;
	}
	return p;
}

tg_peer_t tg_peer_by_phone(tg_t *tg, const char *phone){
	tg_peer_t peer = {0, 0, 0};

	buf_t query = tl_contacts_resolvePhone(phone);
	tl_t *tl = tg_send_query_sync(tg, &query);
	buf_free(query);
	if (tl != NULL && tl->_id == id_contacts_resolvedPeer)
	{
		tl_contacts_resolvedPeer_t *rp = 
			(tl_contacts_resolvedPeer_t *)tl;
		tl_peerUser_t *p = (tl_peerUser_t *)rp->peer_;
		if (p){
			if (p->_id == id_peerUser)
				peer.type = TG_PEER_TYPE_USER;
			else if (p->_id == id_peerChannel)
				peer.type = TG_PEER_TYPE_CHANNEL;
			else if (p->_id == id_peerChat)
				peer.type = TG_PEER_TYPE_CHAT;

			peer.id = p->user_id_;

			if (rp->users_len > 0){
				tl_user_t *user = (tl_user_t *)rp->users_[0];
				if (user){
					peer.access_hash = user->access_hash_;
				}
			}
		}
	}

	if (tl)
		tl_free(tl);

	return peer;
}

static void tg_peer_color_set_to_colors(
		tg_t *tg,
		tg_colors_t *colors,
		tl_t *tl)
{
	if (tl->_id != id_help_peerColorSet &&
		  tl->_id != id_help_peerColorProfileSet)
	{
		ON_ERR(tg, "%s: tl is not colorSet: %s",
				__func__, TL_NAME_FROM_ID(tl->_id));
		return;
	}
	
	if (tl->_id == id_help_peerColorSet)
	{
		tl_help_peerColorSet_t *pcs = 
			(tl_help_peerColorSet_t *)tl;

		if (pcs->colors_ == NULL){
			ON_ERR(tg, "%s: colors is NULL",
					__func__);
			return;
		}
		
		int i;
		for (i = 0; i < pcs->colors_len; ++i) {
			switch (i) {
				case 0:
					colors->rgb0 = pcs->colors_[i];
					break;
				case 1:
					colors->rgb1 = pcs->colors_[i];
					break;
				case 2:
					colors->rgb1 = pcs->colors_[i];
					break;
				
				default:
					break;
			}	
		}
	}else if (tl->_id == id_help_peerColorProfileSet)
	{
		tl_help_peerColorProfileSet_t *pcs = 
			(tl_help_peerColorProfileSet_t *)tl;

		if (pcs->palette_colors_ == NULL){
			ON_ERR(tg, "%s: colors is NULL",
					__func__);
			return;
		}
		
		int i;
		for (i = 0; i < pcs->palette_colors_len; ++i) {
			switch (i) {
				case 0:
					colors->rgb0 = pcs->palette_colors_[i];
					break;
				case 1:
					colors->rgb1 = pcs->palette_colors_[i];
					break;
				case 2:
					colors->rgb1 = pcs->palette_colors_[i];
					break;
				
				default:
					break;
			}	
		}
	}
}

int tg_get_peer_profile_colors(tg_t *tg, uint32_t hash, 
		void *userdata,
		int (*callback)(void *userdata, 
			uint32_t color_id, tg_colors_t *colors, tg_colors_t *dark_colors))
{
	ON_LOG(tg, "%s: start", __func__);
	buf_t query = tl_help_getPeerProfileColors(0);
	tl_t *tl = tg_send_query_sync(tg, &query);
	buf_free(query);
	if (tl == NULL) {
		ON_ERR(tg, "%s: tl is NULL", __func__);
		return 0;
	}
	if (tl->_id == id_help_peerColors)
	{	
		tl_help_peerColors_t *hpc =
			(tl_help_peerColors_t *)tl;

		if (hpc->colors_ == NULL)
			return 0;

		int i;
		for (i = 0; i < hpc->colors_len; ++i) {
			tl_help_peerColorOption_t *pco = 
				(tl_help_peerColorOption_t *)hpc->colors_[i];
			if (pco->_id != id_help_peerColorOption)
				continue;
			
			tg_colors_t colors;
			memset(&colors, 0, sizeof(colors));
			tg_colors_t dark_colors;
			memset(&dark_colors, 0, sizeof(dark_colors));

			if (pco->colors_){
				tg_peer_color_set_to_colors(
						tg, 
						&colors, 
						pco->colors_);
			}
			
			if (pco->dark_colors_){
				tg_peer_color_set_to_colors(
						tg, 
						&dark_colors, 
						pco->dark_colors_);
			}

			// run callback
			if (callback){
				if (callback(userdata, pco->color_id_, &colors, &dark_colors))
				{
					tl_free(tl);
					return 0;
				}
			}
		}
	
		tl_free(tl);
		return hpc->hash_;
	}

	ON_ERR(tg, "%s: tl is not help_peerColors: %s",
			__func__, TL_NAME_FROM_ID(tl->_id));

	tl_free(tl);
	
	return 0;
}

int tg_get_peer_colors(tg_t *tg, uint32_t hash, 
		void *userdata,
		int (*callback)(void *userdata, 
			uint32_t color_id, tg_colors_t *colors, tg_colors_t *dark_colors))
{
	ON_LOG(tg, "%s: start", __func__);
	buf_t query = tl_help_getPeerColors(0);
	tl_t *tl = tg_send_query_sync(tg, &query);
	buf_free(query);
	if (tl == NULL) {
		ON_ERR(tg, "%s: tl is NULL", __func__);
		return 0;
	}
	if (tl->_id == id_help_peerColors)
	{	
		tl_help_peerColors_t *hpc =
			(tl_help_peerColors_t *)tl;

		if (hpc->colors_ == NULL)
			return 0;

		int i;
		for (i = 0; i < hpc->colors_len; ++i) {
			tl_help_peerColorOption_t *pco = 
				(tl_help_peerColorOption_t *)hpc->colors_[i];
			if (pco->_id != id_help_peerColorOption)
				continue;
			
			tg_colors_t colors;
			memset(&colors, 0, sizeof(colors));
			tg_colors_t dark_colors;
			memset(&dark_colors, 0, sizeof(dark_colors));

			if (pco->colors_){
				tg_peer_color_set_to_colors(
						tg, 
						&colors, 
						pco->colors_);
			}
			
			if (pco->dark_colors_){
				tg_peer_color_set_to_colors(
						tg, 
						&dark_colors, 
						pco->dark_colors_);
			}

			// run callback
			if (callback){
				if (callback(userdata, pco->color_id_, &colors, &dark_colors))
				{
					tl_free(tl);
					return 0;
				}
			}
		}
	
		tl_free(tl);
		return hpc->hash_;
	}

	ON_ERR(tg, "%s: tl is not help_peerColors: %s",
			__func__, TL_NAME_FROM_ID(tl->_id));

	tl_free(tl);
	
	return 0;
}
