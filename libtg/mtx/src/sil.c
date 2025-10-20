//
//  sil.c
//  mtx
//
//  Created by Pavel Morozkin on 19.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"

typedef struct abstract_type_
{
  ui32_t id;
  param_t params[max_abstract_params];
} abstract_type_t;

// Reserved
typedef struct abstract_types_
{
  abstract_type_t type_set[max_abstract_params];
} abstract_types_t;

abstract_t sil_abstract(tg_api_type_system_t t)
{
  abstract_t a;
  a.params[0].type = TYPE_ID;

  // dispatcher must be optimized!
  if (t.method_req_pq.id__) {
    a.type = RFC;
    a.params[0].value = api.buf.add_ui32(t.method_req_pq.id__);
    a.params[1] = t.method_req_pq.nonce;
    a.size = 2;
  } else if (t.ctor_P_Q_inner_data.id__) {
    a.type = RFC;
    a.params[0].value = api.buf.add_ui32(t.ctor_P_Q_inner_data.id__);
    a.params[1] = t.ctor_P_Q_inner_data.pq;
    a.params[2] = t.ctor_P_Q_inner_data.p;
    a.params[3] = t.ctor_P_Q_inner_data.q;
    a.params[4] = t.ctor_P_Q_inner_data.nonce;
    a.params[5] = t.ctor_P_Q_inner_data.server_nonce;
    a.params[6] = t.ctor_P_Q_inner_data.new_nonce;
    a.size = 7;
  } else if (t.method_req_DH_params.id__) {
    a.type = RFC;
    a.params[0].value = api.buf.add_ui32(t.method_req_DH_params.id__);
    a.params[1] = t.method_req_DH_params.nonce;
    a.params[2] = t.method_req_DH_params.server_nonce;
    a.params[3] = t.method_req_DH_params.p;
    a.params[4] = t.method_req_DH_params.q;
    a.params[5] = t.method_req_DH_params.public_key_fingerprint;
    a.params[6] = t.method_req_DH_params.encrypted_data;
    a.size = 7;
  } else if (t.ctor_Client_DH_Inner_Data.id__) {
    a.type = RFC;
    a.params[0].value = api.buf.add_ui32(t.ctor_Client_DH_Inner_Data.id__);
    a.params[1] = t.ctor_Client_DH_Inner_Data.nonce;
    a.params[2] = t.ctor_Client_DH_Inner_Data.server_nonce;
    a.params[3] = t.ctor_Client_DH_Inner_Data.retry_id;
    a.params[4] = t.ctor_Client_DH_Inner_Data.g_b;
    a.size = 5;
  } else if (t.method_set_client_DH_params.id__) {
    a.type = RFC;
    a.params[0].value = api.buf.add_ui32(t.method_set_client_DH_params.id__);
    a.params[1] = t.method_set_client_DH_params.nonce;
    a.params[2] = t.method_set_client_DH_params.server_nonce;
    a.params[3] = t.method_set_client_DH_params.encrypted_data;
    a.size = 4;
  } else if (t.method_ping.id__) {
    a.type = API;
    a.params[0].value = api.buf.add_ui32(t.method_ping.id__);
    a.params[1] = t.method_ping.ping_id;
    a.size = 2;
  } else if (t.method_auth_sendCode.id__) {
    a.type = API;
    a.params[0].value = api.buf.add_ui32(t.method_auth_sendCode.id__);
    a.params[1] = t.method_auth_sendCode.phone_number;
    a.params[2] = t.method_auth_sendCode.sms_type;
    a.params[3] = t.method_auth_sendCode.api_id;
    a.params[4] = t.method_auth_sendCode.api_hash;
    a.params[5] = t.method_auth_sendCode.lang_code;
    a.size = 6;
  } else if (t.method_msgs_ack.id__) {
    a.type = API;
    a.params[0].value = api.buf.add_ui32(t.method_msgs_ack.id__);
    a.params[1] = t.method_msgs_ack.msg_ids;
    a.size = 2;
  } else {
    api.log.error("can't abstract");
  }

  return a;
}

tg_api_type_system_t t;
ui32_t reset_tg_api_type_system_flag = 0;

void reset_tg_api_type_system()
{
  tg_api_type_system_t t_ = {};
  t = t_;
}

tg_api_type_system_t sil_concrete(abstract_t a)
{
#ifdef _MSC_VER
  tg_api_type_system_t t = {};
#elif defined __GNUC__
  //tg_api_type_system_t t = {};
  if (!reset_tg_api_type_system_flag) {
    reset_tg_api_type_system();
    reset_tg_api_type_system_flag++;
  }
#endif
  ui32_t id = api.buf.get_ui32(a.params[0].value);
  param_t p;
  p.id = id;
  buf_t_ s = a.params[1].value; // hack
  switch (id) {
    case _id_resPQ:
    {
      t.ctor_ResPQ.id__ = id;
      t.ctor_ResPQ.type__ = RFC;
      p.value = s;
      p.type = TYPE_INT128;
      t.ctor_ResPQ.nonce = api.sel.deserialize_param(p);
      //api.buf.dump(t.ctor_ResPQ.nonce.value);
      s = api.buf.add(s.data + 16, s.size - 16);
      p.value = s;
      p.type = TYPE_INT128;
      t.ctor_ResPQ.server_nonce = api.sel.deserialize_param(p);
      //api.buf.dump(t.ctor_ResPQ.server_nonce.value);
      s = api.buf.add(s.data + 16, s.size - 16);
      p.value = s;
      p.type = TYPE_STRING;
      t.ctor_ResPQ.pq = api.sel.deserialize_param(p);
      //api.buf.dump(t.ctor_ResPQ.pq.value);
      ui32_t l = t.ctor_ResPQ.pq.value.size + 4; // hack
      s = api.buf.add(s.data + l, s.size - l);
      p.value = s;
      p.type = TYPE_VECTOR_LONG;
      t.ctor_ResPQ.server_public_key_fingerprints = api.sel.deserialize_param(p);
      //api.buf.dump(t.ctor_ResPQ.server_public_key_fingerprints.value);

      break;
    }
    case _id_Server_DH_Params_ok:
    {
      ctor_Server_DH_Params_ok_t c;
      c.id__ = id;
      c.type__ = RFC;
      p.value = s;
      p.type = TYPE_INT128;
      c.nonce = api.sel.deserialize_param(p);
      //api.buf.dump(c.nonce.value);
      s = api.buf.add(s.data + 16, s.size - 16);
      p.value = s;
      p.type = TYPE_INT128;
      c.server_nonce = api.sel.deserialize_param(p);
      //api.buf.dump(c.server_nonce.value);
      s = api.buf.add(s.data + 16, s.size - 16);
      p.value = s;
      p.type = TYPE_STRING;
      c.encrypted_answer = api.sel.deserialize_param(p);
      //api.buf.dump(c.encrypted_answer.value);
      t.ctor_Server_DH_Params.ctor_Server_DH_Params_ok = c;

      break;
    }
    case _id_server_DH_inner_data:
    {
      ctor_Server_DH_inner_data_t c;
      c.id__ = id;
      c.type__ = RFC;
      p.value = s;
      p.type = TYPE_INT128;
      c.nonce = api.sel.deserialize_param(p);
      //api.buf.dump(c.nonce.value);
      s = api.buf.add(s.data + 16, s.size - 16);
      p.value = s;
      p.type = TYPE_INT128;
      c.server_nonce = api.sel.deserialize_param(p);
      //api.buf.dump(c.server_nonce.value);
      s = api.buf.add(s.data + 16, s.size - 16);
      p.value = s;
      p.type = TYPE_INT;
      c.g = api.sel.deserialize_param(p);
      //api.buf.dump(c.g.value);
      s = api.buf.add(s.data + 4, s.size - 4);
      p.value = s;
      p.type = TYPE_STRING;
      c.dh_prime = api.sel.deserialize_param(p);
      ui32_t l = c.dh_prime.value.size + 4; // hack
      //api.buf.dump(c.dh_prime.value);
      s = api.buf.add(s.data + l, s.size - l);
      p.value = s;
      p.type = TYPE_STRING;
      c.g_a = api.sel.deserialize_param(p);
      l = c.g_a.value.size + 4; // hack
      //api.buf.dump(c.g_a.value);
      s = api.buf.add(s.data + l, s.size - l);
      p.value = s;
      p.type = TYPE_INT;
      c.server_time = api.sel.deserialize_param(p);
      //api.buf.dump(c.server_time.value);
      t.ctor_Server_DH_inner_data = c;

      break;
    }
    case _id_dh_gen_ok:
    {
      ctor_Set_client_DH_params_answer_ok_t c;
      c.id__ = id;
      c.type__ = RFC;
      p.value = s;
      p.type = TYPE_INT128;
      c.nonce = api.sel.deserialize_param(p);
      //api.buf.dump(c.nonce.value);
      s = api.buf.add(s.data + 16, s.size - 16);
      p.value = s;
      p.type = TYPE_INT128;
      c.server_nonce = api.sel.deserialize_param(p);
      //api.buf.dump(c.server_nonce.value);
      s = api.buf.add(s.data + 16, s.size - 16);
      p.value = s;
      p.type = TYPE_INT128;
      c.new_nonce_hash1 = api.sel.deserialize_param(p);
      //api.buf.dump(c.new_nonce_hash1.value);
      t.ctor_Set_client_DH_params_answer.ctor_Set_client_DH_params_answer_ok = c;

      break;
    }
    case _id_msg_container:
    {
      //api.buf.dump(s);
      ctor_MessageContainer_t c;
      c.id__ = id;
      c.type__  = API;
      p.value = s;
      p.type = TYPE_VECTOR_MESSAGE;
      buf_t_ content = api.buf.add(p.value.data, p.value.size); // hack
      p.value = api.buf.add_ui32(_id_Vector); // hack
      p.value = api.buf.cat(p.value, content);
      p = api.sel.deserialize_param(p);
      buf_t_ b;

      for (int i = 0; i < 2; ++i) {
        //api.buf.dump(p.value);
        b = api.hdl.deheader(p.value, CTER);
        abstract_t a = api.sel.deserialize(b);
        t = api.sil.concrete(a);
        ui32_t l = b.size + 16; // msg_id, seqn, len
        p.value = api.buf.add(p.value.data + l, p.value.size - l);
      }

      break;
    }
    case _id_new_session_created:
    {
      ctor_NewSession_t c;
      c.id__ = id;
      c.type__ = API;
      p.value = s;
      p.type = TYPE_LONG;
      c.first_msg_id = api.sel.deserialize_param(p);
      //api.buf.dump(c.first_msg_id.value);
      s = api.buf.add(s.data + 8, s.size - 8);
      p.value = s;
      p.type = TYPE_LONG;
      c.unique_id = api.sel.deserialize_param(p);
      //api.buf.dump(c.unique_id.value);
      s = api.buf.add(s.data + 8, s.size - 8);
      p.value = s;
      p.type = TYPE_LONG;
      c.server_salt = api.sel.deserialize_param(p);
      //api.buf.dump(c.server_salt.value);
      t.ctor_NewSession = c;

      break;
    }
    case _id_pong:
    {
      ctor_Pong_t c;
      c.id__ = id;
      c.type__ = API;
      p.value = s;
      p.type = TYPE_LONG;
      c.msg_id = api.sel.deserialize_param(p);
      //api.buf.dump(c.msg_id.value);
      s = api.buf.add(s.data + 8, s.size - 8);
      p.value = s;
      p.type = TYPE_LONG;
      c.ping_id = api.sel.deserialize_param(p);
      //api.buf.dump(c.ping_id.value);
      t.ctor_Pong = c;

      break;
    }
    case _id_bad_msg_notification:
    {
      api.log.error("id_bad_msg_notification received");

      break;
    }
    default:
    {
      printf("current id: %.8x\n", id);
      api.log.error("unknown id");

      break;
    }
  }

  return t;
}
