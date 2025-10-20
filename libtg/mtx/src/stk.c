//
//  stk.c
//  mtx
//
//  Created by Pavel Morozkin on 19.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"

abstract_t stk_drive(abstract_t a)
{
  buf_t_ s = api.sel.serialize(a);
	printf("serialize:\n");
	api.buf.dump(s);
  buf_t_ s1 = api.hdl.header(s, a.type);
	printf("header:\n");
	api.buf.dump(s1);
  buf_t_ e = api.enl.encrypt(s1, a.type);
	printf("encrypt:\n");
	api.buf.dump(e);
  buf_t_ t = api.trl.transport(e);
	printf("transport:\n");
	api.buf.dump(t);
  buf_t_ nr = api.net.drive(t, a.stk_mode);
	printf("response:\n");
	api.buf.dump(nr);
  abstract_t ar = {};

  switch (a.stk_mode) {
    case SEND_RECEIVE:
    {
      buf_t_ tr = api.trl.detransport(nr);
      //api.buf.dump(tr);
      buf_t_ d = api.enl.decrypt(tr, a.type);
      //api.buf.dump(d);
      buf_t_ s1r = api.hdl.deheader(d, a.type);
      //api.buf.dump(s1r);
      ar = api.sel.deserialize(s1r);

      break;
    }
    case SEND: {
      break;
    }
    default: {
      break;
    }
  }

  return ar;
}
