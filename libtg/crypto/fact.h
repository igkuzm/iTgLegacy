/**
 * File              : fact.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.11.2024
 * Last Modified Date: 22.11.2024
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#ifndef TL_FACT_H
#define TL_FACT_H

#ifdef __cplusplus
#define EXTERNC extern "C"
#else
#define EXTERNC
#endif

#include <stdint.h>

EXTERNC void factor(uint64_t pq, uint32_t * p, uint32_t * q);

#endif
