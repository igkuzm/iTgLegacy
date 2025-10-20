/**
 * File              : buf.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 21.11.2024
 * Last Modified Date: 21.01.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#ifndef TL_BUF_H
#define TL_BUF_H

#include <stdio.h>
#include <stdint.h>

typedef	struct buf_ {
	unsigned char * data;
	uint32_t   size;
	uint32_t   asize;
	void  *aptr;
} buf_t;

extern buf_t    buf_new();
extern int      buf_init(buf_t *buf);
extern int      buf_realloc(buf_t *buf, uint32_t size);
extern buf_t    buf_add(uint8_t *data, uint32_t size);
extern buf_t    buf_add_buf(buf_t);
extern buf_t    buf_add_bufs(int n, ...);
extern buf_t    buf_cat(buf_t dest, buf_t src);
extern buf_t    buf_cat_ui32(buf_t dest, uint32_t);
extern buf_t    buf_cat_ui64(buf_t dest, uint64_t);
extern buf_t    buf_cat_double(buf_t dest, double);
extern buf_t    buf_cat_data(buf_t dest, uint8_t *data, uint32_t len);
extern buf_t    buf_cat_rand(buf_t dest, uint32_t);
extern void     buf_dump(buf_t);
extern char *   buf_sdump(buf_t);
extern uint8_t  buf_cmp(buf_t, buf_t);
extern buf_t    buf_swap(buf_t);
extern buf_t    buf_add_ui32(uint32_t);
extern buf_t    buf_add_ui64(uint64_t);
extern buf_t    buf_add_double(double);
extern uint32_t buf_get_ui32(buf_t);
extern uint64_t buf_get_ui64(buf_t);
extern double   buf_get_double(buf_t);
extern buf_t    buf_rand(uint32_t s);
extern buf_t    buf_xor(buf_t, buf_t);
extern void     buf_free(buf_t);
extern char*    buf_to_base64(buf_t);
extern buf_t    buf_from_base64(const char*);

#define buf_strdup(__b) strndup((char *)__b.data, __b.size)

#endif
