//
//  api.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"
#include "../include/net.h"
#include "../include/std.h"
#include "../include/buf.h"
#include "../include/app.h"
#include "../include/log.h"
#include "../include/crc.h"
#include "../include/trl.h"
#include "../include/rfc.h"
#include "../include/srl.h"
#include "../include/cmn.h"
#include "../include/sel.h"
#include "../include/enl.h"
#include "../include/tml.h"
#include "../include/hsh.h"
#include "../include/cry.h"
#include "../include/stk.h"
#include "../include/sil.h"
#include "../include/scl.h"
#include "../include/hdl.h"

#ifdef __GNUC__

api_t api =
{
  .std =
  {
    .time                 = std_time,
  },
  .net =
  {
    .open                 = net_open,
    .close                = net_close,
    .drive                = net_drive,
  },
  .buf =
  {
    .add                  = buf_add_,
    .cat                  = buf_cat_,
    .dump                 = buf_dump_,
    .cmp                  = buf_cmp_,
    .swap                 = buf_swap_,
    .add_ui32             = buf_add_ui32_,
    .add_ui64             = buf_add_ui64_,
    .get_ui32             = buf_get_ui32_,
    .get_ui64             = buf_get_ui64_,
    .rand                 = buf_rand_,
    .xor                  = buf_xor_,
  },
  .app =
  {
    .open                 = app_open,
    .run                  = app_run,
    .close                = app_close,
  },
  .log =
  {
    .info                 = log_info,
    .error                = log_error,
    .debug                = log_debug,
    .assert               = log_assert,
    .hex                  = log_hex,
  },
  .crc =
  {
    .crc32                = crc_crc32,
  },
  .trl =
  {
    .init                 = trl_init,
    .transport            = trl_transport,
    .detransport          = trl_detransport,
  },
  .rfc =
  {
    .init                 = rfc_init,
  },
  .srl =
  {
    .init                 = srl_init,
    .auth                 = srl_auth,
    .ping                 = srl_ping,
  },
  .cmn =
  {
    .fact                 = cmn_fact,
    .pow_mod              = cmn_pow_mod,
  },
  .sel =
  {
    .init                 = sel_init,
    .serialize_id         = sel_serialize_id,
    .serialize_param      = sel_serialize_param,
    .deserialize_param    = sel_deserialize_param,
    .serialize_string     = sel_serialize_string,
    .deserialize_string   = sel_deserialize_string,
    .serialize            = sel_serialize,
    .deserialize          = sel_deserialize,
    .deserialize_vector   = sel_deserialize_vector,
  },
  .enl =
  {
    .encrypt              = enl_encrypt,
    .decrypt              = enl_decrypt,
  },
  .tml = &tml_api,
  .hsh =
  {
    .sha1                 = hsh_sha1,
  },
  .cry =
  {
    .rsa_e                = cry_rsa_e,
    .aes_e                = cry_aes_e,
    .aes_d                = cry_aes_d,
  },
  .stk =
  {
    .drive                = stk_drive,
  },
  .sil =
  {
    .abstract             = sil_abstract,
    .concrete             = sil_concrete,
  },
  .scl =
  {
    .open                 = scl_open,
    .run                  = scl_run,
    .close                = scl_close,
  },
  .hdl =
  {
    .header               = hdl_header,
    .deheader             = hdl_deheader,
  }
};

#elif defined _MSC_VER

api_t api =
{
  {
    std_time,
  },
  {
    net_open,
    net_close,
    net_drive,
  },
  {
    buf_add,
    buf_cat,
    buf_dump,
    buf_cmp,
    buf_swap,
    buf_add_ui32,
    buf_add_ui64,
    buf_get_ui32,
    buf_get_ui64,
    buf_rand,
    buf_xor,
  },
  {
    app_open,
    app_run,
    app_close,
  },
  {
    log_info,
    log_error,
    log_debug,
    log_assert,
    log_hex,
  },
  {
    crc_crc32,
  },
  {
    trl_init,
    trl_transport,
    trl_detransport,
  },
  {
    rfc_init,
  },
  {
    srl_init,
    srl_auth,
    srl_ping,
  },
  {
    cmn_fact,
    cmn_pow_mod,
  },
  {
    sel_init,
    sel_serialize_id,
    sel_serialize_param,
    sel_deserialize_param,
    sel_serialize_string,
    sel_deserialize_string,
    sel_serialize,
    sel_deserialize,
    sel_deserialize_vector,
  },
  {
    enl_encrypt,
    enl_decrypt,
  },
  &tml_api,
  {
    hsh_sha1,
  },
  {
    cry_rsa_e,
    cry_aes_e,
    cry_aes_d,
  },
  {
    stk_drive,
  },
  {
    sil_abstract,
    sil_concrete,
  },
  {
    scl_open,
    scl_run,
    scl_close,
  },
  {
    hdl_header,
    hdl_deheader,
  }
};

#else
#error Do not know how to initialize api
#endif
