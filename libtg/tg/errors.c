#include "errors.h"
#include "auth.h"
#include <stdbool.h>

static int tg_error_get_num(
		const char *error, const char *pattern)
{
	char *str = 
		strstr(error, pattern);
	if (str){
		// reconnect to another DC
		str += strlen(pattern);
		int n = atoi(str);
		return n;
	}
	return 0;
}

const dc_t * 
tg_error_phone_migrate(tg_t *tg, const char *error)
{
	if (!error)
		return NULL;

	int n = tg_error_get_num(error, "PHONE_MIGRATE_");
	if (n)
		return &DCs[n - 1];

	return NULL;
}

const dc_t * 
tg_error_file_migrate(tg_t *tg, const char *error)
{
	if (!error)
		return NULL;

	int n = tg_error_get_num(error, "FILE_MIGRATE_");
	if (n)
		return &DCs[n - 1];

	return NULL;
}

int 
tg_error_flood_wait(tg_t *tg, const char *error)
{
	if (!error)
		return 0;
	
	int n = tg_error_get_num(error, "FLOOD_WAIT_");
	if (n)
		return n;

	return 0;
}

AUTH_ERR_CODE tg_error_auth_err_code(tg_t *tg, const char *error)
{
	if (!error)
		return AUTH_ERR_CODE_OK;

	if (strcmp(error, "SESSION_PASSWORD_NEEDED") == 0)
		return SESSION_PASSWORD_NEEDED;
	
	if (strcmp(error, "AUTH_RESTART") == 0)
		return AUTH_RESTART;
	
	if (strcmp(error, "PHONE_CODE_EXPIRED") == 0)
		return PHONE_CODE_EXPIRED;
	
	if (strcmp(error, "PHONE_NUMBER_UNOCCUPIED") == 0)
		return PHONE_NUMBER_UNOCCUPIED;
	
	if (strcmp(error, "SESSION_PASSWORD_NEEDED") == 0)
		return SESSION_PASSWORD_NEEDED;

	return AUTH_ERR_CODE_OK;
}
