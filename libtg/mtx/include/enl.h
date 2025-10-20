//
//  enl.h
//  mtx
//
//  Created by Pavel Morozkin on 18.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__enl__
#define __mtx__enl__

#include "types.h"

extern buf_t_ enl_encrypt(buf_t_, msg_t);
extern buf_t_ enl_decrypt(buf_t_, msg_t);

typedef enum get_params_mode_
{
  MODE_C2S,
  MODE_S2C,
} get_params_mode_t;

typedef struct aes_params_
{
  buf_t_         aes_key;
  buf_t_         aes_iv;
} aes_params_t;

extern aes_params_t enl_get_params(buf_t_, buf_t_, get_params_mode_t);

#endif /* defined(__mtx__enl__) */
