#include "../config.h"
#include "tg.h"
#include "net.h"
#include <stdio.h>
#include <stdlib.h>
#include "strtok_foreach.h"
#include "../tl/serialize.h"
#include "../mtx/include/types.h"
#include "../mtx/include/api.h"
#include <sys/socket.h>

buf_t initConnection(tg_t *tg, buf_t query)
{
	buf_t initConnection = 
		tl_initConnection(
				tg->apiId,
				PACKAGE_NAME, 
				PACKAGE_VERSION, 
				PACKAGE_VERSION, 
				"ru", 
				"LibTg", 
				"ru", 
				NULL, 
				NULL, 
				&query);
	
	/*ON_LOG_BUF(tg, initConnection, */
			/*"%s: initConnection: ", __func__);*/
	
	buf_t invokeWithLayer = 
		tl_invokeWithLayer(
				API_LAYER, &initConnection);
	
	/*ON_LOG_BUF(tg, invokeWithLayer, */
			/*"%s: invokeWithLayer: ", __func__);*/
	
	return invokeWithLayer;
}

tl_user_t *
tg_is_authorized(tg_t *tg)
{
	if (tg->key.size){
		ON_LOG(tg, "have auth_key with len: %d", tg->key.size);

		// init connection and get config
		buf_t getConfig = tl_help_getConfig();
		buf_t init = initConnection(tg, getConfig);
		buf_free(getConfig);
		
		tl_t *tl = tg_send_query_sync(tg, &init); 
		buf_free(init);

		if (tl == NULL || tl->_id !=id_config){
			ON_ERR(tg, "can't get config!");
			return NULL;
		}

		tg->config = (tl_config_t *)tl;
		tl = NULL;

		// check if authorized
		InputUser iuser = tl_inputUserSelf();
		/*ON_LOG_BUF(tg, iuser, "%s: InputUser: ", __func__);*/
		
		buf_t getUsers = 
			tl_users_getUsers(&iuser, 1);	
		/*ON_LOG_BUF(tg, getUsers, "%s: getUsers: ", __func__);*/
		buf_free(iuser);

		tl = tg_send_query_sync(tg, &getUsers); 
		buf_free(getUsers);

		if (tl == NULL){
			return NULL;
		}

		if (tl->_id == id_vector){
			tl_vector_t *vector = (tl_vector_t *)tl;
			ON_LOG(tg, "got vector with len: %d", vector->len_);
			/*ON_LOG_BUF(tg, vector->data_, "VECTOR DATA: ");*/
			tl_t *user = tl_deserialize(&vector->data_);
			if (user && user->_id == id_user){
				return (tl_user_t *)user;
			}
		}

		return NULL;
	}

	ON_ERR(tg, "NEED_TO_AUTHORIZE");
	return NULL;
}

tl_auth_sentCode_t *
tg_auth_sendCode(tg_t *tg, const char *phone_number) 
{
	tl_t *tl = NULL;
	ON_LOG(tg, "%s", __func__);
	
	// init connection and get config
	buf_t getConfig = tl_help_getConfig();
	buf_t init = initConnection(tg, getConfig);
	buf_free(getConfig);
	
	tl = tg_send_query_sync(tg, &init); 
	buf_free(init);

	if (tl == NULL || tl->_id !=id_config){
		ON_ERR(tg, "can't get config!");
		return NULL;
	}

	tg->config = (tl_config_t *)tl;
	
	// get tokens from database 
	buf_t t[20]; int tn = 0;
	char *auth_tokens = auth_tokens_from_database(tg);
	if (auth_tokens){
		strtok_foreach(auth_tokens, ";", token){
			t[tn++] = 
				buf_add((uint8_t*)token, strlen(token)); 
		}
	}
	
	CodeSettings codeSettings = tl_codeSettings(
			false,
		 	false,
		 	false,
		 	false,
		 	false, 
			false,
		 	auth_tokens ? t : NULL,
		 	tn,
		 	NULL,
		 	NULL);

    /*ON_LOG_BUF(tg, codeSettings, */
			/*"%s: codeSettings: ", __func__);*/

	buf_t sendCode = 
		tl_auth_sendCode(
				phone_number, 
				tg->apiId, 
				tg->apiHash, 
				&codeSettings);
	/*ON_LOG_BUF(tg, sendCode, */
			/*"%s: sendCode: ", __func__);*/
	buf_free(codeSettings);

	tl = tg_send_query_sync(tg, &sendCode); 
	buf_free(sendCode);

	if (tl == NULL){
		return NULL;
	}

	if (tl->_id == id_rpc_error){
		tl_rpc_error_t *error = (tl_rpc_error_t *)tl;
		char *str = 
			strstr((char *)error->error_message_.data, "PHONE_MIGRATE_");
		if (str){
			str += strlen("PHONE_MIGRATE_");
			int dc = atoi(str);
			const char *ip = 
				tg_ip_address_for_dc(tg, dc);
			if (!ip)
				return NULL;
			tg_set_server_address(tg, ip, 443);
			// generate auth key
			api.net.close(shared_rc.net);
			tg->key.size = 0;
			return tg_auth_sendCode(tg, phone_number);
		}
	}
		
	if (tl && tl->_id == id_auth_sentCode){
		return (tl_auth_sentCode_t *)tl;
	}
	if (tl)
		tl_free(tl);
	return NULL;
}

tl_user_t *
tg_auth_signIn(tg_t *tg, tl_auth_sentCode_t *sentCode, 
		const char *phone_number, const char *phone_code) 
{
	ON_LOG(tg, "%s", __func__);
	buf_t signIn = 
		tl_auth_signIn(
				phone_number, 
				(char *)sentCode->phone_code_hash_.data, 
				phone_code, 
				NULL);
	
	tl_t *tl = 
		tg_send_query_sync(tg, &signIn);
	buf_free(signIn);
	
	if (tl && tl->_id == id_auth_authorization){
		tl_auth_authorization_t *auth =
			(tl_auth_authorization_t *)tl;

		if (auth->setup_password_required_){
			// throw error
			ON_ERR(tg, "SESSION_PASSWORD_NEEDED");
			return NULL;
		}
		
		if (auth->future_auth_token_.size > 0){
		// save auth token
			char auth_token[BUFSIZ];
			strncpy(
				auth_token,
				((char *)auth->future_auth_token_.data),
				auth->future_auth_token_.size);
			auth_token_to_database(tg, auth_token);
		}
		
		// save auth_key_id 
		auth_key_to_database(tg, tg->key);

		// save ip address
		ip_address_to_database(tg, tg->ip);
		
		return (tl_user_t *)auth->user_;
	}

	if (tl)
		tl_free(tl);

	return NULL;
}
