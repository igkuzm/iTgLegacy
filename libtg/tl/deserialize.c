#include "buf.h"
#include "tl.h"
#include "names.h"
#include "free.h"
#include "deserialize.h"
#include "deserialize_table.h"
#include <stdio.h>
#include <string.h>

uint32_t deserialize_ui32(buf_t *b){
	uint32_t c;
	c = buf_get_ui32(*b);
	b->data += 4;
	b->size -= 4;
	//*b = buf_add(b->data + 4, b->size - 4);
	return c;
}

uint64_t deserialize_ui64(buf_t *b){
	uint64_t c;
	c = buf_get_ui64(*b);
	b->data += 8;
	b->size -= 8;
	//*b = buf_add(b->data + 8, b->size - 8);
	return c;
}

double deserialize_double(buf_t *b){
	double c;
	c = buf_get_double(*b);
	b->data += 8;
	b->size -= 8;
	//*b = buf_add(b->data + 8, b->size - 8);
	return c;
}

buf_t deserialize_buf(buf_t *b, int size){
	buf_t ret = buf_add(b->data, size);
	b->data += size;
	b->size -= size;
	//*b = buf_add(b->data + size, b->size - size);
	return ret;
}

buf_t deserialize_bytes(buf_t *b)
{
	/*buf_dump(*b);*/
  buf_t s;
	buf_init(&s);

  buf_t byte = buf_add(b->data, 4);
  int offset = 0;
  uint32_t len = 0;

  if (byte.data[0] <= 253) {
    len = byte.data[0];
		// skip 1 byte
		//*b = buf_add(b->data + 1, b->size - 1);
		b->data += 1;
		b->size -= 1;
		s = buf_add(b->data, len);
		offset = 1;
  } else if (byte.data[0] >= 254) {
    uint8_t start = 0xfe;
    buf_t s1 = buf_add((uint8_t *)&start, 1);
    buf_t s2 = buf_add(b->data, 1);

    if (!buf_cmp(s1, s2)) {
      printf("can't deserialize bytes");
    }

    buf_t len_ = buf_add(b->data + 1, 3);
    len_.size = 4; // hack
    len = buf_get_ui32(len_);
		// skip 4 bytes
		//*b = buf_add(b->data + 4, b->size - 4);
		b->data += 4;
		b->size -= 4;
    s = buf_add(b->data, len);
  } else {
    printf("can't deserialize bytes");
  }
	
	//*b = buf_add(b->data + len, b->size - len);
	b->data += len;
	b->size -= len;
  
	// padding
	int pad = (4 - ((len + offset) % 4)) % 4;
	if (pad) {
		//*b = buf_add(b->data + pad, b->size - pad);
		b->data += pad;
		b->size -= pad;
	}

	/*printf("STRING: %s\n", s.data);*/
  return s;
}

static tl_deserialize_function *get_fun(unsigned int id){
	int i,
			len = sizeof(tl_deserialize_table)/
				    sizeof(*tl_deserialize_table);

	for (i = 0; i < len; ++i)
		if(tl_deserialize_table[i].id == id)
			return tl_deserialize_table[i].fun;

	return NULL;
}

tl_t * tl_deserialize(buf_t *buf)
{
	uint32_t *id = (uint32_t *)(buf->data);
	if (!*id)
		return NULL;

	// find id in deserialize table
	tl_deserialize_function *fun = get_fun(*id);
	if (!fun){
		printf("can't find deserialization"
				" function for id: %.8x\n", *id);
		printf("dump:\n");
		buf_dump(*buf);

		return NULL;
	}

	// run deserialization function
	return fun(buf);
}


uint32_t id_from_tl_buf(buf_t tl_buf){
	return *(uint32_t *)tl_buf.data;
}

mtp_message_t deserialize_mtp_message(buf_t *b){
	mtp_message_t msg; 
	memset(&msg, 0, sizeof(mtp_message_t));
	
	msg.msg_id = deserialize_ui64(b);
	//printf("mtp_message msg_id: %0.16lx\n", msg.msg_id);

	msg.seqno = deserialize_ui32(b);
	//printf("mtp_message seqno: %0.8x\n", msg.seqno);

	msg.bytes = deserialize_ui32(b);
	//printf("mtp_message bytes: %d\n", msg.bytes);

	msg.body = deserialize_buf(b, msg.bytes);
		//buf_add(b->data, msg.bytes);
	//*b = buf_add(b->data + msg.bytes, b->size - msg.bytes);
	//printf("mtp_message body: %s (%.x)\n",
			//TL_NAME_FROM_ID(id_from_tl_buf(msg.body)),
			//id_from_tl_buf(msg.body));
	return msg;
}

static tl_free_function *get_free_fun(unsigned int id){
	/*fprintf(stderr, "tl_free\n");*/
	int i,
			len = sizeof(tl_deserialize_table)/
				    sizeof(*tl_deserialize_table);

	for (i = 0; i < len; ++i)
		if(tl_deserialize_table[i].id == id)
			return tl_free_table[i].fun;

	return NULL;
}

void tl_free(tl_t *tl)
{
	if (tl == NULL)
		return;

	//fprintf(stderr, "%s: %s\n", 
			//__func__, TL_NAME_FROM_ID(tl->_id));
	
	// find id in free table
	tl_free_function *fun = get_free_fun(tl->_id);
	if (!fun){
		printf("can't find free"
				" function for id: %.8x\n", tl->_id);
		return;
	}

	// run free function
	fun(tl);
}
