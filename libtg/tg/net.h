/**
 * File              : net.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 21.11.2024
 * Last Modified Date: 15.01.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#ifndef TL_NET_H
#define TL_NET_H

#include <stdint.h>
#include "../libtg.h"

extern int   tg_net_open(tg_t*, const char*ip, int port);
extern void  tg_net_close(tg_t*,int);

#endif /* defined(TL_NET_H) */
