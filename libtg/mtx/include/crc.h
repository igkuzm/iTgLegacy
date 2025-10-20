//
//  crc32.h
//  mtx
//
//  Created by Pavel Morozkin on 07.12.13.
//  Copyright (c) 2013 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__crc32__
#define __mtx__crc32__

#include "types.h"
#include <stdint.h>
#include <stdlib.h>

extern uint32_t crc32_(uint32_t crc, const void * buf, size_t size);
extern buf_t_ crc_crc32(const buf_t_);

#endif /* defined(__mtx__crc32__) */
