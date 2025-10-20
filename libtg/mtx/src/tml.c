//
//  tml.c
//  mtx
//
//  Created by Pavel Morozkin on 18.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/tml.h"
#include "../include/macro.h"

#ifdef __GNUC__

methods_t methods__ =
{
  .req_pq =
  {
    .init = method_req_pq_init,
    .drive = method_req_pq_drive,
  },
  .req_DH_params =
  {
    .init = method_req_DH_params_init,
    .drive = method_req_DH_params_drive,
  },
  .set_client_DH_params =
  {
    .init = method_set_client_DH_params_init,
    .drive = method_set_client_DH_params_drive,
  },
  .ping =
  {
    .init = method_ping_init,
    .drive = method_ping_drive,
  },
  .auth_sendCode =
  {
    .init = method_auth_sendCode_init,
    .drive = method_auth_sendCode_drive,
  },
  .msgs_ack =
  {
    .init = method_msgs_ack_init,
    .drive = method_msgs_ack_drive,
  },
};

ctors_t ctors__ =
{
  .P_Q_inner_data =
  {
    .init = ctor_P_Q_inner_data_init,
    .drive = ctor_P_Q_inner_data_drive,
  },
  .Server_DH_inner_data =
  {
    .init = ctor_Server_DH_inner_data_init,
    .drive = ctor_Server_DH_inner_data_drive,
  },
  .Client_DH_Inner_Data =
  {
    .init = ctor_Client_DH_Inner_Data_init,
    .drive = ctor_Client_DH_Inner_Data_drive,
  },
};

tml_api_t tml_api =
{
  .methods = &methods__,
  .ctors =   &ctors__,
};

#elif defined _MSC_VER

methods_t methods__ =
{
  {
    method_req_pq_init,
    method_req_pq_drive,
  },
  {
    method_req_DH_params_init,
    method_req_DH_params_drive,
  },
  {
    method_set_client_DH_params_init,
    method_set_client_DH_params_drive,
  },
};

ctors_t ctors__ =
{
  {
    ctor_P_Q_inner_data_init,
    ctor_P_Q_inner_data_drive,
  },
  {
    ctor_Server_DH_inner_data_init,
    ctor_Server_DH_inner_data_drive,
  },
  {
    ctor_Client_DH_Inner_Data_init,
    ctor_Client_DH_Inner_Data_drive,
  },
};

tml_api_t tml_api =
{
  &methods__,
  &ctors__,
};

#endif
