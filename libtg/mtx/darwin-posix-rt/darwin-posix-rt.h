/*!
  Copyright 2012, Mattias Holm
  mattias.holm(at)openorbit.org
 */

#ifndef DARWIN_POSIX_RT_EMU
#define DARWIN_POSIX_RT_EMU

#include <time.h>

#define CLOCK_REALTIME		0
#define CLOCK_MONOTONIC		1

int clock_gettime(int clock_id, struct timespec *ts);

#endif /*! DARWIN_POSIX_RT_EMU */
