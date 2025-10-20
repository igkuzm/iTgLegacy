//
//  hsh.c
//  mtx
//
//  Created by Pavel Morozkin on 19.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/types.h"
#include "../include/sha1.h"
#include "../include/buf.h"
#include "../include/sha256.h"

buf_t_ hsh_sha1(buf_t_ b)
{
  buf_t_ h;
	/*buf_init(&h);*/
  sha1(b.data, b.size, h.data);
  h.size = 20;

  return h;
}

buf_t_ hsh_sha256(buf_t_ b)
{
  buf_t_ h;
	/*buf_init(&h);*/
  sha256_bytes(b.data, b.size, h.data);
  h.size = 256;

  return h;
}
