//
//  hdl.h
//  mtx
//
//  Created by Pavel Morozkin on 24.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__hdl__
#define __mtx__hdl__

#include "tgt.h"

extern buf_t_ hdl_header(buf_t_ b, msg_t t);
extern buf_t_ hdl_deheader(buf_t_ b, msg_t t);
long long get_current_time();

#endif /* defined(__mtx__hdl__) */
