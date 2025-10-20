//
//  enl.c
//  mtx
//
//  Created by Pavel Morozkin on 18.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"
#include "../include/enl.h"
#include "../include/buf.h"

buf_t_ enl_encrypt(buf_t_ b, msg_t t)
{
  buf_t_ e = {};
	//buf_init(&e);

  switch (t) {
    case API:
    {
      buf_t_ key = shared_rc_get_key();
      buf_t_ key_hash = api.hsh.sha1(key);
      buf_t_ auth_key_id = api.buf.add(key_hash.data + 12, 8);
      e = api.buf.cat(e, auth_key_id);
      buf_t_ data_hash = api.hsh.sha1(b);
      buf_t_ msg_key = api.buf.add(data_hash.data + 4, 16);
      e = api.buf.cat(e, msg_key);
      ui32_t pad_ = (16 - (b.size % 16)) % 16;

      if (pad_) {
        buf_t_ pad = {};
				//buf_init(&pad);
        pad.size = pad_;
        b = api.buf.cat(b, pad);
      }

      aes_params_t p = enl_get_params(key, msg_key, MODE_C2S);
      buf_t_ enc = api.cry.aes_e(b, p.aes_key, p.aes_iv);
      e = api.buf.cat(e, enc);

      break;
    }
    case RFC:
    {
      buf_t_ key = {};

      e = api.buf.add(key.data, 8);
      e = api.buf.cat(e, b);

      break;
    }
    default:
    {
      api.log.error("unknown type");

      break;
    }
  }

  return e;
}

buf_t_ enl_decrypt(buf_t_ m, msg_t t)
{
  buf_t_ d;
	//buf_init(&d);

  switch (t) {
    case API:
    {
      buf_t_ key = shared_rc_get_key();
      buf_t_ key_hash = api.hsh.sha1(key);
      buf_t_ auth_key_id = api.buf.add(key_hash.data + 12, 8);
      buf_t_ auth_key_id_ = api.buf.add(m.data, 8);

      if (!api.buf.cmp(auth_key_id, auth_key_id_)) {
        api.log.error("different auth key id's");
      }

      m = api.buf.add(m.data + 8, m.size - 8);
      buf_t_ msg_key = api.buf.add(m.data, 16);
      m = api.buf.add(m.data + 16, m.size - 16);
      aes_params_t p = enl_get_params(key, msg_key, MODE_S2C);
      d = api.cry.aes_d(m, p.aes_key, p.aes_iv);
      buf_t_ l_ = api.buf.add(d.data + 28, 4);
      ui32_t l = api.buf.get_ui32(l_);
      ui32_t pad_ = (16 - (l % 16)) % 16;

      if (pad_) {
        d = api.buf.add(d.data, d.size - pad_);
      }

      buf_t_ data_hash = api.hsh.sha1(d);
      buf_t_ msg_key_ = api.buf.add(data_hash.data + 4, 16);

      if (!api.buf.cmp(msg_key_, msg_key)) {
        api.log.error("different msg key's");
      }

      break;
    }
    case RFC:
    {
      buf_t_ key = {};
      key.size = 8;

      buf_t_ d_key = api.buf.add(m.data, 8);

      if (!api.buf.cmp(key, d_key)) {
        api.log.error("trl_transport: keys mismatch");
      }

      d = api.buf.add(m.data + 8, m.size - 8);

      break;
    }
    default:
    {
      break;
    }
  }

  return d;
}


aes_params_t enl_get_params(buf_t_ auth_key, buf_t_ msg_key, get_params_mode_t m)
{
  ui8_t x = 0;

  switch (m) {
    case MODE_C2S:
    {
      x = 0;

      break;
    }
    case MODE_S2C:
    {
      x = 8;

      break;
    }
    default:
    {
      api.log.error("unknown mode");

      break;
    }
  }

  buf_t_ aes_key = {};
	//buf_init(&aes_key);
  buf_t_ aes_iv = {};
	//buf_init(&aes_iv);
  buf_t_ tmp = api.buf.add(msg_key.data, 16);
  tmp = api.buf.cat(tmp, api.buf.add(auth_key.data + x, 32));
  buf_t_ hash = api.hsh.sha1(tmp);
  aes_key = api.buf.cat(aes_key, api.buf.add(hash.data, 8));
  aes_iv = api.buf.cat(aes_iv, api.buf.add(hash.data + 8, 12));
  tmp = api.buf.add(auth_key.data + 32 + x, 16);
  tmp = api.buf.cat(tmp, api.buf.add(msg_key.data, 16));
  tmp = api.buf.cat(tmp, api.buf.add(auth_key.data + 48 + x, 16));
  hash = api.hsh.sha1(tmp);
  aes_key = api.buf.cat(aes_key, api.buf.add(hash.data + 8, 12));
  aes_iv = api.buf.cat(aes_iv, api.buf.add(hash.data, 8));
  tmp = api.buf.add(auth_key.data + 64 + x, 32);
  tmp = api.buf.cat(tmp, api.buf.add(msg_key.data, 16));
  hash = api.hsh.sha1(tmp);
  aes_key = api.buf.cat(aes_key, api.buf.add(hash.data + 4, 12));
  aes_iv = api.buf.cat(aes_iv, api.buf.add(hash.data + 16, 4));
  tmp = api.buf.add(msg_key.data, 16);
  tmp = api.buf.cat(tmp, api.buf.add(auth_key.data + 96 + x, 32));
  hash = api.hsh.sha1(tmp);
  aes_iv = api.buf.cat(aes_iv, api.buf.add(hash.data, 8));
  aes_params_t p;
  p.aes_key = aes_key;
  p.aes_iv = aes_iv;

  return p;
}
