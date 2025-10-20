//
//  trl.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/trl.h"
#include "../include/api.h"
#include "../include/buf.h"

trl_t trl_init()
{
  trl_t trl;

  return trl;
}

buf_t_ trl_transport(buf_t_ buf)
{
  buf_t_ b = {};
	/*buf_init(&b);	*/

	// intermediate header
	b = api.buf.add_ui32(buf.size);
	b = api.buf.cat(b, buf);

  // add size
  //ui32_t len_ = buf.size + 12;
  //ui8_t * len_ptr = (ui8_t *)&len_;
  //buf_t_ len = api.buf.add(len_ptr, sizeof(buf.size));
  //b = api.buf.cat(b, len);
  // add seq
  //ui32_t seqn = shared_rc_get_seqn();
  //buf_t_ seq = api.buf.add_ui32(seqn);
  //b = api.buf.cat(b, seq);
  // add buf
  //b = api.buf.cat(b, buf);
  // add crc
  //buf_t_ crc = api.crc.crc32(b);
  //b = api.buf.cat(b, crc);

  return b;
}

buf_t_ trl_detransport(buf_t_ a)
{
  if (!a.size) {
    api.log.error("trl_transport: received nothing");
  }

  // check len
  buf_t_ a_len = api.buf.add(a.data, 4);
  buf_t_ a_len_ = api.buf.add((ui8_t *)&a.size, 4);

  if (!api.buf.cmp(a_len, a_len_)) {
    api.log.error("trl_transport: len mismatch");
  }
	
  // check seq
  //buf_t_ a_seq = api.buf.add(a.data+4, 4);
  //if(!api.buf.cmp(seq, a_seq))
  //api.log.error("trl_transport: seq mismatch");

  // check crc
  //a.size -= 4;
  //buf_t_ a_crc = api.crc.crc32(a);
  //a.size += 4;
  //buf_t_ a_crc_ = api.buf.add(a.data + a.size - 4, 4);

  //if (!api.buf.cmp(a_crc, a_crc_)) {
    //api.log.error("trl_transport: crc mismatch");
  //}

  // remove
  //a.size -= 12;
  //a = api.buf.add(a.data + 8, a.size);
  //ui32_t err_ = 0xfffffe6c;
  //buf_t_ err = api.buf.add_ui32(err_);

  //if (a.size == 4 && api.buf.cmp(a, err)) {
    //api.log.error("trl_transport: 404");
  //}
	
	a = api.buf.add(a.data + 4, a.size - 4);
  return a;
}
