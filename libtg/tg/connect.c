#include "tg.h"
#include "strtok_foreach.h"
#include <stdio.h>
#include <string.h>
#include "net.h"

struct tg_connect_t {
	void *userdata;
	char * (*callback)(void *userdata, TG_AUTH auth,
			const tl_t *tl, const char *error);
	char error[BUFSIZ];
};

static void on_err(void *d, const char *err)
{
	struct tg_connect_t *t = d;
	if (err)
		strcpy(t->error, err);
	else
		t->error[0] = 0;

	if (t->callback)
		t->callback(t->userdata, TG_AUTH_ERROR, NULL, err);
}

static void on_log(void *d, const char *msg)
{
	struct tg_connect_t *t = d;
	if (msg)
		strcpy(t->error, msg);
	else
		t->error[0] = 0;

	if (t->callback)
		t->callback(t->userdata, TG_AUTH_INFO, NULL, msg);
}


#define _TG_CB(auth, tl, ...)\
	({\
	 char err[256];\
	 sprintf(err, __VA_ARGS__);\
	 char *ret = NULL;\
	 if (callback){\
		ret = callback(userdata, auth, (tl_t *)tl, err);\
	 }\
	 ret;\
	})

int tg_connect(
		tg_t *tg,
		void *userdata,
		char * (*callback)(
			void *userdata,
			TG_AUTH auth,
			const tl_t *tl,
			const char *error))
{
	struct tg_connect_t t = 
	{userdata, callback, 0};

	// save previous error handler
	/*void  *_prev_on_err_data = tg->on_err_data;*/
	/*void (*_prev_on_err_call)= tg->on_err;*/

	tg_set_on_error(tg, &t, on_err);
	tg_set_on_log(tg, &t, on_log);

	// check if authorized
	tl_user_t *user = tg_is_authorized(tg);
	if (user){
		_TG_CB(TG_AUTH_SUCCESS, user, "authorized!");
		return 0;
	}

	// try to get phone_number
	char * phone_number = phone_number_from_database(tg);
	if (!phone_number){
		phone_number = 
			_TG_CB(TG_AUTH_PHONE_NUMBER_NEEDED, NULL, 
					"enter phone number (+7XXXXXXXXXX)");
	}
	if (!phone_number){
		_TG_CB(TG_AUTH_ERROR, NULL, "phone number is NULL");
		return 1;
	}
	_TG_CB(TG_AUTH_INFO, NULL, "phone number: %s", phone_number);

	// send authorization code
	tl_auth_sentCode_t *sentCode = 
		tg_auth_sendCode(tg, phone_number);

	// check if need password
	//if (strcmp(t.error, "SESSION_PASSWORD_NEEDED") == 0)
	//{
		//// ask user for password
		//char *password = 
			//_TG_CB(TG_AUTH_PASSWORD_NEEDED, sentCode, "enter password");
		//if (!password){
			//_TG_CB(TG_AUTH_ERROR, sentCode, "password is NULL");
			//return 1;
		//}
		//_TG_CB(TG_AUTH_INFO, sentCode, "password: %s", password);

		//[> TODO: connect with password <]
		//_TG_CB(TG_AUTH_ERROR, sentCode, 
				//"password auth is not implyed yet!");
		//return 1;
	//}

	if (!sentCode)
		return 1;

	// ask user for code
	char *phone_code = 
		_TG_CB(TG_AUTH_PHONE_CODE_NEEDED, sentCode, "enter code");
	if (!phone_code){
		_TG_CB(TG_AUTH_ERROR, sentCode, "phone code is NULL");
		return 1;
	}
	_TG_CB(TG_AUTH_INFO, sentCode, "phone code: %s", phone_code);

	user = 
		tg_auth_signIn(tg, sentCode, phone_number, phone_code);
	if (user){
		// authorized!
		_TG_CB(TG_AUTH_SUCCESS, user, "authorized!");
		return 0;
	}

	// check if need password
	if (strcmp(t.error, "SESSION_PASSWORD_NEEDED") == 0)
	{
		// ask user for password
		char *password = 
			_TG_CB(TG_AUTH_PASSWORD_NEEDED, sentCode, "enter password");
		if (!password){
			_TG_CB(TG_AUTH_ERROR, sentCode, "password is NULL");
			return 1;
		}
		_TG_CB(TG_AUTH_INFO, sentCode, "password: %s", password);

		user = 
			tg_auth_check_password(tg, password);
			if (user){
				// authorized!
				_TG_CB(TG_AUTH_SUCCESS, user, "authorized!");
			return 0;
		}

		_TG_CB(TG_AUTH_ERROR, sentCode, 
				"password is incorrect!");
		return 1;
	}

	/* TODO: AUTH_RESTART, PHONE_CODE_EXPIRED, 
	 * PHONE_NUMBER_UNOCCUPIED */

	return 1;
}
