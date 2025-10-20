//
//  types.c
//  mtx
//
//  Created by Pavel Morozkin on 25.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include "../include/types.h"

shared_rc_t shared_rc;

void reset_shared_rc()
{
  shared_rc.key.size = 0;
  shared_rc.salt.size = 0;
  shared_rc.ssid.size = 0;
  shared_rc.seqn = -1;
  shared_rc.seqnh = 0;
  shared_rc.net.sockfd = 0;
}

buf_t_ shared_rc_get_key()
{
  return shared_rc.key;
}

buf_t_ shared_rc_get_salt()
{
  return shared_rc.salt;
}

buf_t_ shared_rc_get_ssid()
{
  return shared_rc.ssid;
}

ui32_t shared_rc_get_seqn()
{
  return ++shared_rc.seqn;
}

ui32_t shared_rc_get_seqnh()
{
  return ++shared_rc.seqnh;
}

net_t shared_rc_get_net()
{
  return shared_rc.net;
}

buf_t_ shared_rc_get_last_msg_id()
{
  return shared_rc.last_msg_id;
};
