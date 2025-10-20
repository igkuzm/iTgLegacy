//
//  cry.c
//  mtx
//
//  Created by Pavel Morozkin on 19.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"
#include "../include/rsa.h"
#include "../include/aes.h"
#include "../include/buf.h"

buf_t_ cry_rsa_e(buf_t_ b)
{
  buf_t_ r = {};
	/*buf_init(&r);*/
  r.size = 256;

  rsa(b.data, b.size, r.data, r.size);

  return r;
}

buf_t_ cry_aes_e(buf_t_ b, buf_t_ key, buf_t_ iv)
{
	//printf("%s\n", __func__);
  buf_t_ r = {};
	/*buf_init(&r);*/
	//if (b.size > r.size)
		//buf_realloc(&r, b.size * 2);

	int l = aes_e(b.data, r.data, b.size, key.data, iv.data);

  if (!l) {
    api.log.error("error during aes encryption");
  }

  r.size = l;

	//printf("%s done\n", __func__);
  return r;
}

buf_t_ cry_aes_d(buf_t_ b, buf_t_ key, buf_t_ iv)
{
	//printf("%s\n", __func__);
  buf_t_ r = {};
	/*buf_init(&r);*/
	//if (b.size > r.size)
		//buf_realloc(&r, b.size * 2);
  
	int l = aes_d(b.data, r.data, b.size, key.data, iv.data);

  if (!l) {
    api.log.error("error during aes decryption");
  }

  r.size = l;

	//printf("%s done\n", __func__);
  return r;
}
