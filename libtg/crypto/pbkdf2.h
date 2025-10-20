#ifndef TG_PBKDF2_H
#define TG_PBKDF2_H
#include "../tl/buf.h"

extern buf_t tg_pbkdf2_sha512(
		buf_t password, buf_t salt, int iteration_count);

#endif /* ifndef TG_PBKDF2_H */
