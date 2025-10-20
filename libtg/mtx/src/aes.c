//
//  aes.c
//  mtx
//
//  Created by Pavel Morozkin on 14.12.13.
//  Copyright (c) 2013 Pavel Morozkin. All rights reserved.
//

#include "../include/aes.h"

#ifdef __GNUC__
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
#endif

int aes_d(const unsigned char * in, unsigned char * out, const unsigned int l, const unsigned char * k, unsigned char * iv)
{
  AES_KEY key;
  AES_set_decrypt_key(k, 256, &key);
  AES_ige_encrypt(in, out, l, &key, iv, AES_DECRYPT);

  return l;
}

int aes_e(const unsigned char * in, unsigned char * out, const unsigned int l, unsigned char * k, unsigned char * iv)
{
  AES_KEY key;
  AES_set_encrypt_key(k, 256, &key);
  AES_ige_encrypt(in, out, l, &key, iv, AES_ENCRYPT);

  return l;
}
