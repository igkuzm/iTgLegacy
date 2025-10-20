//
//  log.c
//  mtx
//
//  Created by Pavel Morozkin on 17.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//

#include <stdio.h>
#include <stdlib.h>
#include "../include/types.h"
#include "../include/setup.h"

void log_info(_string_t s, ...)
{
  fprintf(stdout, product);
  fprintf(stdout, ": info: %s\n", s);
}

void log_error(_string_t s)
{
  fprintf(stdout, product);
  fprintf(stdout, ": error: %s\n", s);
  //exit(EXIT_FAILURE);
}

void log_debug()
{
  return;
}

void log_assert()
{
  return;
}

void log_hex(array_t a, ui32_t s)
{
  int m = 16;
  int b = 8;
  int f = 0;

  fprintf(stderr, "size : %d\n", s);

  for (ui32_t i = 0; i < s; i++) {
    if (!i) {
      fprintf(stderr, "%.4x | ", i), f = 1;
    }

    if (!(i % m) && i) {
      fprintf(stderr, "\n%.4x | ", i), f = 1;
    }

    if (!(i % b) && i && !f) {
      fprintf(stderr, " ");
    }

    fprintf(stderr, "%.2x ", a[i]);
    f = 0;
  }

  fprintf(stderr, "\n");
}
