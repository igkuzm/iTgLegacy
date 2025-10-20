//
//  sel.h
//  mtx
//
//  Created by Pavel Morozkin on 18.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__sel__
#define __mtx__sel__

#include "types.h"
#include "api.h"

extern sel_t sel_init(trl_t trl);
extern buf_t_ sel_serialize_id(buf_t_ b);
extern buf_t_ sel_serialize_param(param_t p);
extern param_t sel_deserialize_param(param_t p);
extern buf_t_ sel_serialize_string(buf_t_ b);
extern buf_t_ sel_deserialize_string(buf_t_ b);
extern buf_t_ sel_serialize(abstract_t a);
extern abstract_t sel_deserialize(buf_t_ b);
extern buf_t_ sel_deserialize_vector(param_t p);

#endif /* defined(__mtx__sel__) */
