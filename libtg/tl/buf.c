//
//  buf.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "buf.h"
#include "str.h"
#include "base64.h"

char * tl_log_hex(unsigned char * a, uint32_t s)
{
	struct str str;
	str_init(&str);

  int m = 16;
  int b = 8;
  int f = 0;

  str_appendf(&str, "size : %d\n", s);

  for (uint32_t i = 0; i < s; i++) {
    if (!i) {
      str_appendf(&str, "%.4x | ", i), f = 1;
    }

    if (!(i % m) && i) {
      str_appendf(&str, "\n%.4x | ", i), f = 1;
    }

    if (!(i % b) && i && !f) {
      str_appendf(&str, " ");
    }

    str_appendf(&str, "%.2x ", a[i]);
    f = 0;
  }

  /*str_appendf(&str, "\n");*/

	return str.str;
}

int buf_init(buf_t *buf)
{
	buf->aptr = malloc(BUFSIZ + 1); 
	if (!buf->aptr){
		perror("malloc");
		return 1;
	}
	buf->asize = BUFSIZ;
	buf->size = 0;
	buf->data = buf->aptr;
	memset(buf->aptr, 0, buf->asize + 1);
	return 0;
}

buf_t buf_new(){
	buf_t b;
	buf_init(&b);
	return b;
}

int buf_realloc(buf_t *buf, uint32_t size)
{
	long offset = (void *)buf->data - buf->aptr;
	if (size > buf->asize){
		void *ptr = realloc(buf->aptr, size + 1);
		if (!ptr){
			perror("realloc");
			return 1;
		}
		buf->aptr = ptr;
		buf->data = buf->aptr + offset;
		memset(&buf->aptr[buf->asize], 0,
				size - buf->asize + 1);
		buf->asize = size;
	}
	return 0;
}

buf_t buf_add(uint8_t *data, uint32_t size)
{
  buf_t b;
	buf_init(&b);

  if (size > b.asize) {
		buf_realloc(&b, size);
  }

	uint32_t i;
  for (i = 0; i < size; ++i) {
    b.data[i] = data[i];
  }

  b.size = size;

  return b;
}

buf_t buf_add_buf(buf_t buf)
{
	return buf_add(buf.data, buf.size);
}

buf_t buf_add_bufs(int n, ...)
{
	buf_t buf;
	buf_init(&buf);
	va_list argv;
	va_start(argv, n);
	int i;
	for (i = 0; i < n; ++i) {
		buf_t arg = va_arg(argv, buf_t);
		buf = buf_cat(buf, arg);
	}
	va_end(argv);
	return buf;
}

buf_t buf_cat(buf_t dest, buf_t src)
{
  uint32_t s = dest.size + src.size;

  if (s > dest.asize) {
		buf_realloc(&dest, s);
  }

  int offset = dest.size;

  for (uint32_t i = 0; i < src.size; ++i) {
    dest.data[i + offset] = src.data[i];
  }

  dest.size = s;

  return dest;
}

void buf_dump(buf_t b)
{
  char *str = tl_log_hex(b.data, b.size);
	printf("%s\n", str);
	free(str);
}

char * buf_sdump(buf_t b)
{
  return tl_log_hex(b.data, b.size);
}

uint8_t buf_cmp(buf_t a, buf_t b)
{
  if (a.size != b.size) {
    printf("Error: buf_cmp: different sizes\n");
  }

  for (uint32_t i = 0; i < a.size; ++i) {
    if (a.data[i] != b.data[i]) {
      return 0;
    }
  }

  return 1;
}

buf_t buf_swap(buf_t b)
{
  unsigned char * lo = (unsigned char *)b.data;
  unsigned char * hi = (unsigned char *)b.data + b.size - 1;
  unsigned char swap;

  while (lo < hi) {
    swap = *lo;
    *lo++ = *hi;
    *hi-- = swap;
  }

  return b;
}

buf_t buf_add_ui32(uint32_t v)
{
  return buf_add((uint8_t *)&v, 4);
}

buf_t buf_add_ui64(uint64_t v)
{
  return buf_add((uint8_t *)&v, 8);
}

buf_t buf_add_double(double v)
{
  return buf_add((uint8_t *)&v, 8);
}

uint32_t buf_get_ui32(buf_t b)
{
  return *(uint32_t *)b.data;
}

uint64_t buf_get_ui64(buf_t b)
{
  return *(uint64_t *)b.data;
}

double buf_get_double(buf_t b)
{
  return *(double *)b.data;
}

buf_t buf_rand(uint32_t s)
{
  buf_t b = {};
	buf_init(&b);

  srand((unsigned int)time(NULL));

  for (uint32_t i = 0; i < s; i++) {
    b.data[i] = rand() % 256;
  }

  b.size = s;

  return b;
}

buf_t buf_xor(buf_t a, buf_t b)
{
  if (a.size != b.size) {
    printf("Error: buf_cmp: different sizes\n");
  }

  buf_t r;
	buf_init(&r);
  if (a.size > r.asize) {
		buf_realloc(&r, a.size);
  }

  for (uint32_t i = 0; i < a.size; ++i) {
    r.data[i] = a.data[i] ^ b.data[i];
  }

  r.size = a.size;
  
  return r;
}

buf_t buf_cat_ui32(buf_t dest, uint32_t i)
{
	buf_t src = buf_add_ui32(i);
	buf_t buf = buf_cat(dest, src);
	free(src.aptr);
	return buf; 
}

buf_t buf_cat_ui64(buf_t dest, uint64_t i){
	buf_t src = buf_add_ui64(i);
	buf_t buf = buf_cat(dest, src);
	free(src.aptr);
	return buf; 
}

buf_t buf_cat_double(buf_t dest, double i){
	buf_t src = buf_add_double(i);
	buf_t buf = buf_cat(dest, src);
	free(src.aptr);
	return buf; 
}

buf_t buf_cat_data(buf_t dest, uint8_t *data, uint32_t len){
	buf_t src = buf_add(data, len);
	buf_t buf = buf_cat(dest, src);
	free(src.aptr);
	return buf; 
}

buf_t buf_cat_rand(buf_t dest, uint32_t s)
{
	buf_t src = buf_rand(s);
	buf_t buf = buf_cat(dest, src);
	free(src.aptr);
	return buf; 
}

void buf_free(buf_t b){
	//fprintf(stderr, "buf_free\n");
	if (b.aptr)
		free(b.aptr);
	b.aptr = NULL;
}

char* buf_to_base64(buf_t b){
	char *r = NULL;
	if (b.size < 1)
		return r;
	
	uint64_t l;
	char *s = base64_encode(
			b.data, 
			b.size, 
			&l);
	
	if (s && l > 0){
		r = strndup(s, l);
		free(s);
	}

	return r;
}

buf_t buf_from_base64(const char *s){
	buf_t b;
	buf_init(&b);
	if (!s)
		return b;
	uint64_t l = 0;
	void * data = base64_decode(
			s, 
			strlen(s), 
			&l);
	if (!data)
		return b;
	
	b = buf_cat_data(b, data, l);
	free(data);
	return b;
}
