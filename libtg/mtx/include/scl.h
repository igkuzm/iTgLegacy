//
//  scl.h
//  mtx
//
//  Created by Pavel Morozkin on 24.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__scl__
#define __mtx__scl__

#include "types.h"

extern scl_t scl_open(char *ip, int port);
extern void scl_run();
extern void scl_close();

#endif /* defined(__mtx__scl__) */
