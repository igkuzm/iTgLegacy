//
//  trl.h
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__trl__
#define __mtx__trl__

#include "types.h"

extern trl_t trl_init();
extern buf_t_ trl_transport(buf_t_);
extern buf_t_ trl_detransport(buf_t_);

#endif /* defined(__mtx__trl__) */
