#include "tl.h"
#include "../mtx/include/sel.h"
#include <string.h>
#include <stdbool.h>

buf_t serialize_bytes(
		uint8_t *bytes, size_t size)
{
	buf_t s = {};
	if (size <= 253){
		s = buf_add((uint8_t *)&size, 1);
    buf_t b = buf_add(bytes, size);
    s = buf_cat(s, b);
    int pad = (4 - (s.size % 4)) % 4;
    buf_t p = {};
		buf_init(&p);
    p.size = pad;
    s = buf_cat(s, p);
	} else {
		uint8_t start = 0xfe;
    s = buf_add((uint8_t *)&start, 1);
    buf_t len = buf_add((uint8_t *)&size, 3);
    s = buf_cat(s, len);
    buf_t b = buf_add(bytes, size);
    s = buf_cat(s, b);
    int pad = (4 - (s.size % 4)) % 4;

    if (pad) {
      buf_t p = {};
			buf_init(&p);
      p.size = pad;
      s = buf_cat(s, p);
    }
	}
	return s;
}

buf_t serialize_string(const char *string)
{
	return serialize_bytes(
			(uint8_t *)string, strlen(string));
}

static bool flag_is_set(int value, int flag)
{
	int flagb = (1 << flag);
	return (value & flagb) != flagb;
}

buf_t serialize_str(buf_t b)
{
  buf_t s;
	buf_init(&s);
  ui32_t size = b.size;

  if (size <= 253) {
    s = buf_add((ui8_t *)&size, 1);
    s = buf_cat(s, b);
    int pad = (4 - (s.size % 4)) % 4;
    buf_t p;
		buf_init(&p);
    p.size = pad;
    s = buf_cat(s, p);
  } else if (size >= 254) {
    ui8_t start = 0xfe;
    s = buf_add((ui8_t *)&start, 1);
    buf_t len = buf_add((ui8_t *)&size, 3);
    s = buf_cat(s, len);
    s = buf_cat(s, b);
    int pad = (4 - (s.size % 4)) % 4;

    if (pad) {
      buf_t p;
			buf_init(&p);
      p.size = pad;
      s = buf_cat(s, p);
    }
  } else {
    api.log.error("can't serialize string");
  }

  return s;
}


