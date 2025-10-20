//
//  tgt.c
//  mtx
//
//  Created by Pavel Morozkin on 18.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include <string.h>
#include "../include/tgt.h"
#include "../include/api.h"
#include "../include/buf.h"

#ifdef __GNUC__

ctor_ResPQ_t ctor_ResPQ =
{
  .type__ = RFC,
  .id__ = 0x05162463,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .pq =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .server_public_key_fingerprints =
  {
    .value = {},
    .type = TYPE_VECTOR_LONG,
  },
};

method_req_pq_t req_pq =
{
  .type__ = RFC,
  .id__ = 0x60469778,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .ctor_ResPQ = {},
};

ctor_Server_DH_Params_ok_t ctor_Server_DH_Params_ok =
{
  .type__ = RFC,
  .id__ = 0xd0e8075c,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .encrypted_answer =
  {
    .value = {},
    .type = TYPE_STRING,
  },
};
ctor_Server_DH_Params_fail_t ctor_Server_DH_Params_fail =
{
  .type__ = RFC,
  .id__ = 0x79cb045d,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .new_nonce_hash =
  {
    .value = {},
    .type = TYPE_INT128,
  },
};

method_req_DH_params_t method_req_DH_params =
{
  .type__ = RFC,
  .id__ = 0xd712e4be,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .p =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .q =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .public_key_fingerprint =
  {
    .value = {},
    .type = TYPE_LONG,
  },
  .encrypted_data =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .ctor_Server_DH_Params = {},
};

ctor_P_Q_inner_data_t ctor_P_Q_inner_data =
{
  .type__ = RFC,
  .id__ = 0x83c95aec,
  .pq =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .p =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .q =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .new_nonce =
  {
    .value = {},
    .type = TYPE_INT256,
  },
};

ctor_Server_DH_inner_data_t ctor_Server_DH_inner_data =
{
  .type__ = RFC,
  .id__ = 0x05890dba,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .g =
  {
    .value = {},
    .type = TYPE_INT,
  },
  .dh_prime =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .g_a =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .server_time =
  {
    .value = {},
    .type = TYPE_INT,
  },
};

ctor_Client_DH_Inner_Data_t ctor_Client_DH_Inner_Data =
{
  .type__ = RFC,
  .id__ = 0x6643b654,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .retry_id =
  {
    .value = {},
    .type = TYPE_LONG,
  },
  .g_b =
  {
    .value = {},
    .type = TYPE_STRING,
  },
};

ctor_Set_client_DH_params_answer_ok_t ctor_Set_client_DH_params_answer_ok =
{
  .type__ = RFC,
  .id__ = 0x3bcbf734,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .new_nonce_hash1 =
  {
    .value = {},
    .type = TYPE_INT128,
  },
};

method_set_client_DH_params_t method_set_client_DH_params =
{
  .type__ = RFC,
  .id__ = 0xf5045f1f,
  .nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .server_nonce =
  {
    .value = {},
    .type = TYPE_INT128,
  },
  .encrypted_data =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .ctor_Set_client_DH_params_answer = {},
};

ctor_Pong_t ctor_Pong =
{
  .type__ = RFC,
  .id__ = 0x347773c5,
  .msg_id =
  {
    .value = {},
    .type = TYPE_LONG,
  },
  .ping_id =
  {
    .value = {},
    .type = TYPE_LONG,
  },
};

method_ping_t method_ping =
{
  .type__ = RFC,
  .id__ = 0x7abe77ec,
  .ping_id =
  {
    .value = {},
    .type = TYPE_LONG,
  },
  .ctor_Pong = {},
};

ctor_auth_SentCode_t ctor_auth_SentCode =
{
  .type__ = RFC,
  .id__ = 0x2215bcbd,
  .phone_registered =
  {
    .value = {},
    .type = TYPE_BOOL,
  },
  .phone_code_hash =
  {
    .value = {},
    .type = TYPE_STRING,
  }
};

method_auth_sendCode_t method_auth_sendCode =
{
  .type__ = RFC,
  .id__ = 0x768d5f4d,
  .phone_number =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .sms_type =
  {
    .value = {},
    .type = TYPE_INT,
  },
  .api_id =
  {
    .value = {},
    .type = TYPE_INT,
  },
  .api_hash =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .lang_code =
  {
    .value = {},
    .type = TYPE_STRING,
  },
  .ctor_auth_SentCode = {},
};

ctor_NewSession_t ctor_NewSession =
{
  .type__ = RFC,
  .id__ = 0x9ec20908,
  .first_msg_id =
  {
    .value = {},
    .type = TYPE_LONG,
  },
  .unique_id =
  {
    .value = {},
    .type = TYPE_LONG,
  },
  .server_salt =
  {
    .value = {},
    .type = TYPE_LONG,
  },
};

method_msgs_ack_t method_msgs_ack =
{
  .type__ = RFC,
  .id__ = 0x62d6b459,
  .msg_ids =
  {
    .value = {},
    .type = TYPE_VECTOR_LONG,
  },
  .ctor_MsgsAck = {},
};

#elif defined _MSC_VER /*WIN32*/

ctor_ResPQ_t ctor_ResPQ =
{
  RFC,
  0x05162463,
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_VECTOR_LONG,
  },
};

method_req_pq_t req_pq =
{
  RFC,
  0x60469778,
  {
    {0},
    TYPE_INT128,
  },
  {},
};

ctor_Server_DH_Params_ok_t ctor_Server_DH_Params_ok =
{
  RFC,
  0xd0e8075c,
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_STRING,
  },
};

ctor_Server_DH_Params_fail_t ctor_Server_DH_Params_fail =
{
  RFC,
  0x79cb045d,
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
};

method_req_DH_params_t method_req_DH_params =
{
  RFC,
  0xd712e4be,
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_LONG,
  },
  {
    {0},
    TYPE_STRING,
  },
  {},
};

ctor_P_Q_inner_data_t ctor_P_Q_inner_data =
{
  RFC,
  0x83c95aec,
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT256,
  },
};

ctor_Server_DH_inner_data_t ctor_Server_DH_inner_data =
{
  RFC,
  0x05890dba,
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT,
  },
  {
    {0},
    TYPE_STRING,
  }
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_INT,
  },
};

ctor_Client_DH_Inner_Data_t ctor_Client_DH_Inner_Data =
{
  RFC,
  0x6643b654,
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_LONG,
  },
  {
    {0},
    TYPE_STRING,
  },
};

ctor_Set_client_DH_params_answer_ok_t ctor_Set_client_DH_params_answer_ok =
{
  RFC,
  0x3bcbf734,
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
};

method_set_client_DH_params_t method_set_client_DH_params =
{
  RFC,
  0xf5045f1f,
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_INT128,
  },
  {
    {0},
    TYPE_STRING,
  },
  {},
};

method_ping_t method_ping =
{
  RFC,
  0x7abe77ec,
  {
    {0},
    TYPE_LONG,
  },
  {},
};

ctor_auth_SentCode_t ctor_auth_SentCode =
{
  RFC,
  0x2215bcbd,
  {
    {0},
    TYPE_BOOL,
  },
  {
    {0},
    TYPE_STRING,
  }
};

method_auth_sendCode_t method_auth_sendCode =
{
  RFC,
  0x768d5f4d,
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_INT,
  },
  {
    {0},
    TYPE_INT,
  },
  {
    {0},
    TYPE_STRING,
  },
  {
    {0},
    TYPE_STRING,
  },
  {},
};

ctor_NewSession_t ctor_NewSession =
{
  RFC,
  0x9ec20908,
  {
    {0},
    TYPE_LONG,
  },
  {
    {0},
    TYPE_LONG,
  },
  {
    {0},
    TYPE_LONG,
  },
};

method_msgs_ack_t method_msgs_ack =
{
  RFC,
  0x62d6b459,
  {
    {0},
    TYPE_VECTOR_LONG,
  },
  {0},
};

#endif

method_req_pq_t method_req_pq_init()
{
  method_req_pq_t m = req_pq;
  m.nonce.value = api.buf.rand(16);

  return m;
}

method_req_pq_t method_req_pq_drive(method_req_pq_t m)
{
  tg_api_type_system_t t = {};
  t.method_req_pq = m;
  abstract_t a = api.sil.abstract(t);
  a.stk_mode = SEND_RECEIVE;
  a = api.stk.drive(a);
  m.ctor_ResPQ = api.sil.concrete(a).ctor_ResPQ;

  return m;
}

method_req_DH_params_t
method_req_DH_params_init(method_req_pq_t m1)
{
	printf("%s\n", __func__);
  method_req_DH_params_t m = method_req_DH_params;
  m.nonce = m1.nonce;
  m.server_nonce = m1.ctor_ResPQ.server_nonce;
  ui64_t pq = api.buf.get_ui64(api.buf.swap(m1.ctor_ResPQ.pq.value));
  ui32_t p, q;
  api.cmn.fact(pq, &p, &q);

  if (!(p < q)) {
      SWAP(p, q);
  }

  m.p.value = api.buf.swap(api.buf.add_ui32(p));
  m.q.value = api.buf.swap(api.buf.add_ui32(q));
  m.public_key_fingerprint = m1.ctor_ResPQ.server_public_key_fingerprints;
  ctor_P_Q_inner_data_t c = api.tml->ctors->P_Q_inner_data.init(m1, m);
  buf_t_ d = api.tml->ctors->P_Q_inner_data.drive(c);
  buf_t_ h = api.hsh.sha1(d);
  //api.buf.dump(h);
  //buf_t_ dwh = api.buf.cat(h, d);
  buf_t_ dwh;
	//buf_init(&dwh); 
	dwh = api.buf.cat(dwh, h);
	dwh = api.buf.cat(dwh, d);
  buf_t_ pad = {};
  pad.size = 255 - dwh.size;
  dwh = api.buf.cat(dwh, pad);
  //api.buf.dump(dwh);
  m.encrypted_data.value = api.cry.rsa_e(dwh);
  //api.buf.dump(m.encrypted_data.value);
  m.encrypted_data.type = TYPE_STRING;
  m.ctor_P_Q_inner_data = c;

  return m;
}

method_req_DH_params_t
method_req_DH_params_drive(method_req_DH_params_t m)
{
	printf("%s\n", __func__);
  tg_api_type_system_t t = {};
  t.method_req_DH_params = m;
  abstract_t a = api.sil.abstract(t);
  a.stk_mode = SEND_RECEIVE;
  a = api.stk.drive(a);
  m.ctor_Server_DH_Params = api.sil.concrete(a).ctor_Server_DH_Params;

  return m;
}

ctor_P_Q_inner_data_t
ctor_P_Q_inner_data_init(method_req_pq_t m1, method_req_DH_params_t m2)
{
	printf("%s\n", __func__);
  ctor_P_Q_inner_data_t m = ctor_P_Q_inner_data;
  m.pq = m1.ctor_ResPQ.pq;
  m.p = m2.p;
  m.q = m2.q;
  //api.buf.dump(m.pq.value);
  //api.buf.dump(m.p.value);
  //api.buf.dump(m.q.value);
  m.nonce = m1.nonce;
  //api.buf.dump(m.nonce.value);
  m.server_nonce = m1.ctor_ResPQ.server_nonce;
  //api.buf.dump(m.server_nonce.value);
  //m.new_nonce.value = api.cmn.rand_array(32);
  buf_t_ rand_array = {};
	//buf_init(&rand_array);
	//memset(rand_array.data, 0, 32);
  rand_array.size = 32;
  //buf_t_ rand_array = buf_rand(32);
  m.new_nonce.value = rand_array; // fucking hack
  //api.buf.dump(m.new_nonce.value);
  m.new_nonce.type = TYPE_INT256;

  return m;
}

buf_t_
ctor_P_Q_inner_data_drive(ctor_P_Q_inner_data_t c)
{
	printf("%s\n", __func__);
  tg_api_type_system_t t = {};
  t.ctor_P_Q_inner_data = c;
  buf_t_ s = api.sel.serialize(api.sil.abstract(t));
  api.buf.dump(s);

  return s;
}

ctor_Server_DH_inner_data_t
ctor_Server_DH_inner_data_init(method_req_pq_t m1, method_req_DH_params_t m2)
{
	printf("%s\n", __func__);
  ctor_P_Q_inner_data_t nn = api.tml->ctors->P_Q_inner_data.init(m1, m2); // hack
  buf_t_ new_nonce = nn.new_nonce.value; // hack
  buf_t_ server_nonce = m1.ctor_ResPQ.server_nonce.value;
  // tmp_aes_key := SHA1(new_nonce + server_nonce) + substr (SHA1(server_nonce + new_nonce), 0, 12);
  buf_t_ new_nonce_plus_server_nonce = {};
  new_nonce_plus_server_nonce = api.buf.cat(new_nonce_plus_server_nonce, new_nonce);
  new_nonce_plus_server_nonce = api.buf.cat(new_nonce_plus_server_nonce, server_nonce);
  buf_t_ new_nonce_plus_server_nonce_hash = api.hsh.sha1(new_nonce_plus_server_nonce);
  buf_t_ server_nonce_plus_new_nonce = {};
  server_nonce_plus_new_nonce = api.buf.cat(server_nonce_plus_new_nonce, server_nonce);
  server_nonce_plus_new_nonce = api.buf.cat(server_nonce_plus_new_nonce, new_nonce);
  buf_t_ server_nonce_plus_new_nonce_hash = api.hsh.sha1(server_nonce_plus_new_nonce);
  buf_t_ substr_sha1_server_nonce_new_nonce012 = api.buf.add(server_nonce_plus_new_nonce_hash.data, 12);
  buf_t_ tmp_aes_key = {};
  tmp_aes_key = api.buf.cat(tmp_aes_key, new_nonce_plus_server_nonce_hash);
  tmp_aes_key = api.buf.cat(tmp_aes_key, substr_sha1_server_nonce_new_nonce012);
  buf_t_ substr_sha1_server_nonce_new_nonce128 = api.buf.add(server_nonce_plus_new_nonce_hash.data + 12, 8);
  buf_t_ new_nonce_new_nonce = {};
  new_nonce_new_nonce = api.buf.cat(new_nonce_new_nonce, new_nonce);
  new_nonce_new_nonce = api.buf.cat(new_nonce_new_nonce, new_nonce);
  buf_t_ new_nonce_new_nonce_hash = api.hsh.sha1(new_nonce_new_nonce);
  buf_t_ substr_new_nonce04 = api.buf.add(new_nonce.data, 4);
  buf_t_ tmp_aes_iv = {};
  tmp_aes_iv = api.buf.cat(tmp_aes_iv, substr_sha1_server_nonce_new_nonce128);
  tmp_aes_iv = api.buf.cat(tmp_aes_iv, new_nonce_new_nonce_hash);
  tmp_aes_iv = api.buf.cat(tmp_aes_iv, substr_new_nonce04);
  buf_t_ e = m2.ctor_Server_DH_Params.ctor_Server_DH_Params_ok.encrypted_answer.value;
  buf_t_ answer = api.cry.aes_d(e, tmp_aes_key, tmp_aes_iv);
  // remove hash
  answer = api.buf.add(answer.data + 20, answer.size - 20);
  // remove 8 random bytes
  answer.size -= 8;
  // additional
  ctor_Server_DH_inner_data_t c;
  c.answer = answer;
  c.tmp_aes_key = tmp_aes_key;
  c.tmp_aes_iv = tmp_aes_iv;

  return c;
}

ctor_Server_DH_inner_data_t
ctor_Server_DH_inner_data_drive(buf_t_ b)
{
	printf("%s\n", __func__);
  ctor_Server_DH_inner_data_t c = ctor_Server_DH_inner_data;
  tg_api_type_system_t t = {};
  t.ctor_Server_DH_inner_data = c;
  abstract_t a = api.sel.deserialize(b);
  c = api.sil.concrete(a).ctor_Server_DH_inner_data;

  return c;
}

ctor_Client_DH_Inner_Data_t
ctor_Client_DH_Inner_Data_init(method_req_pq_t m1, ctor_Server_DH_inner_data_t c1)
{
	printf("%s\n", __func__);
  ctor_Client_DH_Inner_Data_t c = ctor_Client_DH_Inner_Data;
  c.nonce = c1.nonce;
  c.server_nonce = c1.server_nonce;
  ui32_t retry_id_ = 0;
  c.retry_id.value = api.buf.add_ui32(retry_id_);
  c.retry_id.type = TYPE_LONG;
  buf_t_ g = c1.g.value;
  g = api.buf.swap(g);
  buf_t_ b = api.buf.rand(256);
  buf_t_ m = c1.dh_prime.value;
  c.g_b.value = api.cmn.pow_mod(g, b, m);
  c.g_b.type = TYPE_STRING;
  // additional
  c.b = b;

  return c;
}

buf_t_
ctor_Client_DH_Inner_Data_drive(ctor_Client_DH_Inner_Data_t c1)
{
	printf("%s\n", __func__);
  tg_api_type_system_t t = {};
  t.ctor_Client_DH_Inner_Data = c1;
  buf_t_ s = api.sel.serialize(api.sil.abstract(t));
  //api.buf.dump(s);

  return s;
}

method_set_client_DH_params_t
method_set_client_DH_params_init(method_req_pq_t m1, method_req_DH_params_t m2)
{
	printf("%s\n", __func__);
  ctor_Server_DH_inner_data_t c = api.tml->ctors->Server_DH_inner_data.init(m1, m2);
  buf_t_ a = c.answer;
  ctor_Server_DH_inner_data_t c1 = api.tml->ctors->Server_DH_inner_data.drive(a);
  ctor_Client_DH_Inner_Data_t c2 = api.tml->ctors->Client_DH_Inner_Data.init(m1, c1);
  buf_t_ data = api.tml->ctors->Client_DH_Inner_Data.drive(c2);
  buf_t_ hash = api.hsh.sha1(data);
  ui32_t pad_ = hash.size + data.size;
  pad_ = (16 - (pad_ % 16)) % 16;
  buf_t_ rand = api.buf.rand(pad_);
  buf_t_ data_with_hash = {};
	//buf_init(&data_with_hash);
  data_with_hash = api.buf.cat(data_with_hash, hash);
  data_with_hash = api.buf.cat(data_with_hash, data);
  data_with_hash = api.buf.cat(data_with_hash, rand);
  buf_t_ encrypted_data = api.cry.aes_e(data_with_hash, c.tmp_aes_key, c.tmp_aes_iv);
  method_set_client_DH_params_t m = method_set_client_DH_params;
  m.nonce = m1.nonce;
  m.server_nonce = m1.ctor_ResPQ.server_nonce;
  m.encrypted_data.value = encrypted_data;
  m.encrypted_data.type = TYPE_STRING;
  // additional
  m.ctor_Server_DH_inner_data = c1;
  m.ctor_Client_DH_Inner_Data = c2;
  // server_salt = substr(new_nonce, 0, 8) XOR substr(server_nonce, 0, 8)
  buf_t_ new_nonce_s = api.buf.add(m2.ctor_P_Q_inner_data.new_nonce.value.data, 8);
  buf_t_ server_nonce_s = api.buf.add(m.server_nonce.value.data, 8);
  m.salt = api.buf.xor(new_nonce_s, server_nonce_s);

  return m;
}
method_set_client_DH_params_t
method_set_client_DH_params_drive(method_set_client_DH_params_t m)
{
	printf("%s\n", __func__);
  tg_api_type_system_t t = {};
  t.method_set_client_DH_params = m;
  abstract_t a = api.sil.abstract(t);
  a.stk_mode = SEND_RECEIVE;
  a = api.stk.drive(a);
  m.ctor_Set_client_DH_params_answer = api.sil.concrete(a).ctor_Set_client_DH_params_answer;
  buf_t_ nonce = m.ctor_Set_client_DH_params_answer.ctor_Set_client_DH_params_answer_ok.nonce.value;
  buf_t_ nonce_ = m.ctor_Server_DH_inner_data.nonce.value;

  if (!api.buf.cmp(nonce, nonce_)) {
    api.log.error("different nonce's");
  }

  buf_t_ server_nonce = m.ctor_Set_client_DH_params_answer.ctor_Set_client_DH_params_answer_ok.server_nonce.value;
  buf_t_ server_nonce_ = m.ctor_Server_DH_inner_data.server_nonce.value;
  if (!api.buf.cmp(server_nonce, server_nonce_)) {
    api.log.error("different server nonce's");
  }

  return m;
}

method_ping_t method_ping_init()
{
  method_ping_t m = method_ping;
  m.ping_id.value = api.buf.add_ui64(0);
  m.ping_id.type = TYPE_LONG;

  return m;
}

extern ui32_t reset_tg_api_type_system_flag; // hack

method_ping_t method_ping_drive(method_ping_t m)
{
  tg_api_type_system_t t = {};
  t.method_ping = m;
  abstract_t a = api.sil.abstract(t);
  a.stk_mode = SEND_RECEIVE;
  api.log.info(">> ping");
  a = api.stk.drive(a);
  api.log.info("<< pong");
  t = api.sil.concrete(a);
  m.ctor_Pong = t.ctor_Pong;

  if (!api.buf.cmp(m.ping_id.value, m.ctor_Pong.ping_id.value)) {
    api.log.error("unexpected ping id");
  }

  if (_id_new_session_created == t.ctor_NewSession.id__) {
    api.log.info(".. new session created");
    //buf_t_ msg_id = shared_rc_get_last_msg_id();
    //method_msgs_ack_t m = api.tml->methods->msgs_ack.init(msg_id);
    //m = api.tml->methods->msgs_ack.drive(m);
    //api.log.info("_mtx: >> ack");
  }

  reset_tg_api_type_system_flag = 0; // hack

  return m;
}

method_auth_sendCode_t method_auth_sendCode_init()
{
  method_auth_sendCode_t m = method_auth_sendCode;
  char * phone_number = "+7XXXXXXXXXX";

  m.phone_number.value = api.buf.add((ui8_t *)phone_number, (ui32_t)strlen(phone_number));
  ui32_t sms_type = 0;
  m.sms_type.value = api.buf.add_ui32(sms_type);
  m.api_id.value = api.buf.add_ui32(_api_id);
  m.api_hash.value = api.buf.add((ui8_t *)_api_hash, 32);
  m.lang_code.value = api.buf.add((ui8_t *)_lang_code, 2);

  return m;
}

method_auth_sendCode_t method_auth_sendCode_drive(method_auth_sendCode_t m)
{
  tg_api_type_system_t t = {};
  t.method_auth_sendCode = m;
  abstract_t a = api.sil.abstract(t);
  a = api.stk.drive(a);
  m.ctor_auth_SentCode = api.sil.concrete(a).ctor_auth_SentCode;

  return m;
}

method_msgs_ack_t method_msgs_ack_init(buf_t_ msg_id)
{
  method_msgs_ack_t m = method_msgs_ack;
  m.msg_ids.value = msg_id;

  return m;
}

method_msgs_ack_t method_msgs_ack_drive(method_msgs_ack_t m)
{
  tg_api_type_system_t t = {};
  t.method_msgs_ack = m;
  abstract_t a = api.sil.abstract(t);
  a.stk_mode = SEND;
  api.stk.drive(a);

  return m;
}
