//
//  srl.h
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__srl__
#define __mtx__srl__

#include "tgt.h"
#include "types.h"

extern srl_t srl_init();
extern srl_t srl_auth();
extern buf_t_ srl_ping();
extern ctor_auth_SentCode_t srl_sendCode(const char	*phone_number);
extern ctor_auth_SentCode_t srl_resendCode(const char *phone_code_hash);
extern ctor_auth_SentCode_t srl_singIn(
		const char *phone_code_hash, const char *phone_code);
extern buf_t_ srl_msgsAck(ui64_t msg_id);
extern abstract_t srl_initConnection(buf_t_ query);
extern abstract_t srl_invokeWithLayer(int layer, buf_t_ query);

#endif /* defined(__mtx__srl__) */
