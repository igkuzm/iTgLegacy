#include "tg.h"
#include <string.h>

char *
tg_strerr(const tl_t *tl)
{
	if (tl == NULL)
		return strdup("OBJECT_IS_NULL");

	char *str = NULL;

	switch (tl->_id) {
		case 0xfffffe6c:
			str = strdup("404_ERROR");
			break;

		case id_rpc_error:
			{
				tl_rpc_error_t *err = 
					(tl_rpc_error_t *)tl;
				str = strndup(
						(char *)err->error_message_.data,
						err->error_message_.size);
			}
			break;
		
		case id_bad_msg_notification:
			{
				tl_bad_msg_notification_t *bmsgn = 
						(tl_bad_msg_notification_t *)tl;
				char err[256];
				sprintf(err, "BAD_MSG_NOTIFICATION: %d",
						bmsgn->error_code_);
				str = strdup(err);
			}
			break;
		
		default:
			{
				char err[256];
				sprintf(err, "UMANAGED TL: tl_%s_t (%.8x)",
						TL_NAME_FROM_ID(tl->_id), tl->_id);
				str = strdup(err);
			}
			break;
	}
	return str;
}
