#include "../tg/tg.h"

buf_t tg_transport(tg_t *tg, buf_t buf)
{
	//ON_LOG(tg, "%s", __func__);
  buf_t b;
	buf_init(&b);
	
	// intermediate header
	b = buf_cat_ui32(b, buf.size);
	b = buf_cat(b, buf);

	// add size
	//uint32_t len = buf.size + 12;
	//uint8_t * len_ptr = (uint8_t *)&len_;
	//buf_t len = buf_add(len_ptr, sizeof(buf.size));
	//b = buf_cat_ui32(b, len);

	//add seq
	//uint32_t seqn = tg->seqn;
	//buf_t seq = buf_add_ui32(tg->seqn);
	//b = buf_cat(b, seq);

	// add buf
	//b = buf_cat(b, buf);

	// add crc
	//buf_t crc = tg_crc_crc32(b);
	//b = buf_cat(b, crc);

	//ON_LOG_BUF(tg, b, "%s: ", __func__);
	return b;
}

buf_t tg_detransport(tg_t *tg, buf_t a)
{
	//ON_LOG(tg, "%s", __func__);
	buf_t b;
	buf_init(&b);
	
	if (!a.size) {
	  ON_LOG(tg, "%s: received nothing", __func__);
	  return b;
	}

	uint32_t len = deserialize_ui32(&a);
	
	if (len == -404 || buf_get_ui32(a) == 0xfffffe6c) {
    ON_ERR(tg, "%s: 404", __func__);
		b = buf_cat_ui32(b, 0xfffffe6c);
		return b;
	}
	
	b = buf_cat(b, a);
 //b = buf_cat_data(b, a.data + 4, a.size - 4);

	// check len
	if (len != b.size) {
		ON_LOG(tg, 
				"%s: len mismatch: expected: %d, got: %d", 
				__func__, len, b.size);
		// we should start new transfer
		b = buf_add_ui32(-405);
	}

  return b;
}
