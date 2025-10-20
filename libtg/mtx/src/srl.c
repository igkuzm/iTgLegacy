//
//  srl.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"
#include "../include/buf.h"

srl_t srl_init()
{
  srl_t srl;
  return srl;
}

srl_t srl_auth()
{
  method_req_pq_t m = api.tml->methods->req_pq.init();
  m = api.tml->methods->req_pq.drive(m);
  method_req_DH_params_t m1 = api.tml->methods->req_DH_params.init(m);
  m1 = api.tml->methods->req_DH_params.drive(m1);
  method_set_client_DH_params_t m2 =
      api.tml->methods->set_client_DH_params.init(m, m1);
  m2 = api.tml->methods->set_client_DH_params.drive(m2);
  buf_t_ g_a = m2.ctor_Server_DH_inner_data.g_a.value;
  buf_t_ b = m2.ctor_Client_DH_Inner_Data.b;
  buf_t_ dh_prime = m2.ctor_Server_DH_inner_data.dh_prime.value;
  buf_t_ key = api.cmn.pow_mod(g_a, b, dh_prime);
  shared_rc.key = key;
  shared_rc.salt = m2.salt;
  srl_t s = {};

  return s;
}

buf_t_ srl_ping()
{
  buf_t_ r = {};
	//buf_init(&r);
  method_ping_t m = api.tml->methods->ping.init();
  api.tml->methods->ping.drive(m);

  return r;
}
