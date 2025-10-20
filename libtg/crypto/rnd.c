#include "cry.h"
#include <openssl/rand.h>

extern buf_t tg_cry_rnd(int l){
	buf_t buf;
	buf_init(&buf);
	RAND_bytes(buf.data, l);
	buf.size = l;
	return buf;
}
