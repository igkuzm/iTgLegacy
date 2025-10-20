//
//  aes.h
//  mtx
//
//  Created by Pavel Morozkin on 14.12.13.
//  Copyright (c) 2013 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__aes__
#define __mtx__aes__

#include <openssl/aes.h>

extern int aes_d(const unsigned char * in, unsigned char * out, const unsigned int l, const unsigned char * k, unsigned char * iv);
extern int aes_e(const unsigned char * in, unsigned char * out, const unsigned int l, unsigned char * k, unsigned char * iv);

#endif /* defined(__mtx__aes__) */
