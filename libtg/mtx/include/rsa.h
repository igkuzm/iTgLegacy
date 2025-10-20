//
//  rsa.h
//  mtx
//
//  Created by Pavel Morozkin on 08.12.13.
//  Copyright (c) 2013 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__rsa__
#define __mtx__rsa__

#include <stddef.h>

extern void rsa(unsigned char * from, size_t from_size, unsigned char * to, size_t to_size);
extern void rand_bytes(unsigned char * s, int l);
extern int pow_mod(unsigned char * y, unsigned char * g, size_t g_s, unsigned char * e, size_t e_s, unsigned char * m, size_t m_s);

#endif /* defined(__mtx__rsa__) */
