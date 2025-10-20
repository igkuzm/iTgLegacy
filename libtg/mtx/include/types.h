//
//  types.h
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef mtx_types_h
#define mtx_types_h

#include <stdint.h>
#include <stdio.h>
#include "setup.h"

typedef uint64_t      ui64_t;

typedef uint32_t      ui32_t;

typedef int32_t       i32_t;

typedef uint8_t       ui8_t;

typedef char      *   _string_t;

typedef ui8_t     *   array_t;

typedef struct buf__
{
	ui8_t         data[max_buf_size];
  ui32_t        size;
} buf_t_;

typedef struct net_
{
  i32_t         sockfd;
} net_t;

typedef struct trl_
{
  // ..
} trl_t;

typedef struct sel_
{
  // ..
} sel_t;

typedef struct rfc_
{
  // ..
} rfc_t;

typedef struct srl_
{
  // ..
} srl_t;

typedef struct scl_
{
  // ..
} scl_t;

typedef struct hdl_
{
  // ..
} hdl_t;

typedef struct app_
{
  ui8_t         exit_code;
  scl_t         scl;
} app_t;

typedef struct shared_rc_
{
  buf_t_         key;
  buf_t_         salt;
  buf_t_         ssid;
  int           seqn;
  ui32_t        seqnh;
  net_t         net;
  buf_t_         last_msg_id;
} shared_rc_t;

extern shared_rc_t shared_rc;
extern void reset_shared_rc();
extern buf_t_ shared_rc_get_key();
extern buf_t_ shared_rc_get_salt();
extern buf_t_ shared_rc_get_ssid();
extern ui32_t shared_rc_get_seqn();
extern ui32_t shared_rc_get_seqnh();
extern net_t shared_rc_get_net();
extern buf_t_ shared_rc_get_last_msg_id();

typedef enum stk_mode_
{
  SEND,
  SEND_RECEIVE,
} stk_mode_t;

#endif
