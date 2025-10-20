//
//  buf.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include <stdlib.h>
#include <time.h>
#include "../include/types.h"
#include "../include/api.h"

buf_t_ buf_add_(ui8_t data[], ui32_t size)
{
  if (size > max_buf_size) {
    api.log.error("can't add to buffer");
  }

  buf_t_ b = {};

  for (ui32_t i = 0; i < size; ++i) {
    b.data[i] = data[i];
  }

  b.size = size;

  return b;
}

buf_t_ buf_cat_(buf_t_ dest, buf_t_ src)
{
  ui32_t s = dest.size + src.size;

  if (s > max_buf_size) {
    api.log.error("can't cat to buffer");
  }

  int offset = dest.size;

  for (ui32_t i = 0; i < src.size; ++i) {
    dest.data[i + offset] = src.data[i];
  }

  dest.size = s;

  return dest;
}

void buf_dump_(buf_t_ b)
{
  if (b.size > max_buf_size) {
    api.log.error("Error: buf_dump: max size reached");
  } else if (!b.size) {
    api.log.error("Error: buf_dump: buffer is empty");
  }

  api.log.hex(b.data, b.size);
}

ui8_t buf_cmp_(buf_t_ a, buf_t_ b)
{
  if (a.size != b.size) {
    api.log.error("Error: buf_cmp: different sizes");
  }

  for (ui32_t i = 0; i < a.size; ++i) {
    if (a.data[i] != b.data[i]) {
      return 0;
    }
  }

  return 1;
}

buf_t_ buf_swap_(buf_t_ b)
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

buf_t_ buf_add_ui32_(ui32_t v)
{
  return api.buf.add((ui8_t *)&v, 4);
}

buf_t_ buf_add_ui64_(ui64_t v)
{
  return api.buf.add((ui8_t *)&v, 8);
}

ui32_t buf_get_ui32_(buf_t_ b)
{
  return *(ui32_t *)b.data;
}

ui64_t buf_get_ui64_(buf_t_ b)
{
  return *(ui64_t *)b.data;
}

buf_t_ buf_rand_(ui32_t s)
{
  buf_t_ b = {};

  srand((unsigned int)time(NULL));

  for (ui32_t i = 0; i < s; i++) {
    b.data[i] = rand() % 256;
  }

  b.size = s;

  return b;
}

buf_t_ buf_xor_(buf_t_ a, buf_t_ b)
{
  if (a.size != b.size) {
    api.log.error("Error: buf_cmp: different sizes");
  }

  buf_t_ r;

  for (ui32_t i = 0; i < a.size; ++i) {
    r.data[i] = a.data[i] ^ b.data[i];
  }

  r.size = a.size;
  
  return r;
}
