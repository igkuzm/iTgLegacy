//
//  sil.h
//  mtx
//
//  Created by Pavel Morozkin on 19.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__sil__
#define __mtx__sil__

#include "tgt.h"

extern abstract_t sil_abstract(tg_api_type_system_t);
extern tg_api_type_system_t sil_concrete(abstract_t);

#endif /* defined(__mtx__sil__) */
