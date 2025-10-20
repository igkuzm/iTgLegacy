#ifndef LIB_TL_H_
#define LIB_TL_H_
#include "tl.h"
#include "api_layer.h"
#include "id.h"
#include "names.h"
#include "struct.h"
#include "methods.h"
#include "deserialize.h"

uint32_t id_from_tl_buf(buf_t tl_buf);
#define STRING_T_TO_STR(__b) (char *)__b.data

void tl_handle_messages(tl_t *tl, void *userda, 
		int (*callback)(tl_t *tl, 
			uint64_t msg_id, uint32_t code, const char *msg));

int gunzip_buf(buf_t *dst, buf_t src);
char *gunzip_buf_err(int err); // handle errors
#endif /* ifndef LIB_TL_H_ */ 
