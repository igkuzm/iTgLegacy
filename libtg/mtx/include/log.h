//
//  log.h
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__log__
#define __mtx__log__

#include "types.h"

extern void log_info(_string_t string, ...);
extern void log_error(_string_t string);
extern void log_debug();
extern void log_assert();
extern void log_hex(array_t, ui32_t);

#endif /* defined(__mtx__log__) */
