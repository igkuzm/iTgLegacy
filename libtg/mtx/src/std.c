//
//  std.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include <time.h>
#include "../include/types.h"

ui32_t std_time()
{
  return (ui32_t)time(0);
}
