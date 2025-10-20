//
//  fact.h
//  mtx
//
//  Created by Pavel Morozkin on 07.12.13.
//  Copyright (c) 2013 Pavel Morozkin. All rights reserved.
//

#ifndef mtx_fact_h
#define mtx_fact_h

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

#include <stdint.h>

EXTERNC void factor(uint64_t pq, uint32_t * p, uint32_t * q);

#endif
