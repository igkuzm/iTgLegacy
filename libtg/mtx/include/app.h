//
//  app.h
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#ifndef __mtx__app__
#define __mtx__app__

#include "types.h"

extern app_t app_open(char *ip, int port);
extern ui8_t app_run(app_t app);
extern ui8_t app_close(app_t app);

#endif /* defined(__mtx__app__) */
