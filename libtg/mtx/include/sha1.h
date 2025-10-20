//
//  sha1.h
//  mtx
//
//  Created by Pavel Morozkin on 07.12.13.
//  Copyright (c) 2013 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__sha1__
#define __mtx__sha1__

#include <stdint.h>
#include <stdlib.h>

/* header */

#define HASH_LENGTH 20
#define BLOCK_LENGTH 64

union _buffer
{
  uint8_t         b[BLOCK_LENGTH];
  uint32_t        w[BLOCK_LENGTH / 4];
};

union _state
{
  uint8_t         b[HASH_LENGTH];
  uint32_t        w[HASH_LENGTH / 4];
};

typedef struct sha1nfo
{
  union           _buffer buffer;
  uint8_t         bufferOffset;
  union _state    state;
  uint32_t        byteCount;
  uint8_t         keyBuffer[BLOCK_LENGTH];
  uint8_t         innerHash[HASH_LENGTH];
} sha1nfo;

/* public API - prototypes - TODO: doxygen */

void sha1_init(sha1nfo * s);
void sha1_writebyte(sha1nfo * s, uint8_t data);
void sha1_write(sha1nfo * s, const char * data, size_t len);
uint8_t * sha1_result(sha1nfo * s);
void sha1_initHmac(sha1nfo * s, const uint8_t * key, int keyLength);
uint8_t * sha1_resultHmac(sha1nfo * s);
void printHash(uint8_t * hash);
unsigned char * sha1(const unsigned char * d, unsigned long n, unsigned char * md);

#endif /* defined(__mtx__sha1__) */
