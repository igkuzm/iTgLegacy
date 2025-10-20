//
//  tml.h
//  mtx
//
//  Created by Pavel Morozkin on 18.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__tml__
#define __mtx__tml__

#include "macro.h"
#include "tgt.h"

typedef struct method_req_pq_api_
{
  METHOD(init, method_req_pq_t)
  METHOD(drive, method_req_pq_t, method_req_pq_t)
} method_req_pq_api_t;

typedef struct method_req_DH_params_api_
{
  METHOD(init, method_req_DH_params_t, method_req_pq_t)
  METHOD(drive, method_req_DH_params_t, method_req_DH_params_t)
} method_req_DH_params_api_t;

typedef struct method_set_client_DH_params_api_
{
  METHOD(init, method_set_client_DH_params_t, method_req_pq_t, method_req_DH_params_t)
  METHOD(drive, method_set_client_DH_params_t, method_set_client_DH_params_t)
} method_set_client_DH_params_api_t;

typedef struct method_auth_sendCode_api_
{
  METHOD(init, method_auth_sendCode_t)
  METHOD(drive, method_auth_sendCode_t, method_auth_sendCode_t)
} method_auth_sendCode_api_t;

typedef struct method_msgs_ack_api_
{
  METHOD(init, method_msgs_ack_t, buf_t_)
  METHOD(drive, method_msgs_ack_t, method_msgs_ack_t)
} method_msgs_ack_api_t;

typedef struct ctor_method_ping_api_
{
  METHOD(init, method_ping_t)
  METHOD(drive, method_ping_t, method_ping_t)
} ctor_method_ping_api_t;

typedef struct ctor_P_Q_inner_data_api_
{
  METHOD(init, ctor_P_Q_inner_data_t, method_req_pq_t, method_req_DH_params_t)
  METHOD(drive, buf_t_, ctor_P_Q_inner_data_t)
} ctor_P_Q_inner_data_api_t;

typedef struct ctor_Server_DH_inner_data_api_
{
  METHOD(init, ctor_Server_DH_inner_data_t, method_req_pq_t, method_req_DH_params_t)
  METHOD(drive, ctor_Server_DH_inner_data_t, buf_t_)
} ctor_Server_DH_inner_data_api_t;

typedef struct ctor_Client_DH_Inner_Data_api_
{
  METHOD(init, ctor_Client_DH_Inner_Data_t, method_req_pq_t, ctor_Server_DH_inner_data_t)
  METHOD(drive, buf_t_, ctor_Client_DH_Inner_Data_t)
} ctor_Client_DH_Inner_Data_api_t;

typedef struct methods_
{
  method_req_pq_api_t                 req_pq;
  method_req_DH_params_api_t          req_DH_params;
  method_set_client_DH_params_api_t   set_client_DH_params;
  ctor_method_ping_api_t              ping;
  method_auth_sendCode_api_t          auth_sendCode;
  method_msgs_ack_api_t               msgs_ack;
} methods_t;

typedef struct constructors_
{
  ctor_P_Q_inner_data_api_t           P_Q_inner_data;
  ctor_Server_DH_inner_data_api_t     Server_DH_inner_data;
  ctor_Client_DH_Inner_Data_api_t     Client_DH_Inner_Data;
} ctors_t;

typedef struct tgt_api_
{
  methods_t   *   methods;
  ctors_t     *   ctors;
} tml_api_t;

extern tml_api_t tml_api;

#endif /* defined(__mtx__tml__) */
