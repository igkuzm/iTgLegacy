//
//  buf.h
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef mtx_buf_h
#define mtx_buf_h

#include "../include/types.h"

extern buf_t_ buf_add_(ui8_t data[], ui32_t size);
extern buf_t_ buf_cat_(buf_t_ dest, buf_t_ src);
extern void buf_dump_(buf_t_);
extern ui8_t buf_cmp_(buf_t_, buf_t_);
extern buf_t_ buf_swap_(buf_t_);
extern buf_t_ buf_add_ui32_(ui32_t);
extern buf_t_ buf_add_ui64_(ui64_t);
extern ui32_t buf_get_ui32_(buf_t_);
extern ui64_t buf_get_ui64_(buf_t_);
extern buf_t_ buf_rand_(ui32_t s);
extern buf_t_ buf_xor_(buf_t_, buf_t_);

#endif
