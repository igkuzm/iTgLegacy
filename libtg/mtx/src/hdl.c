//
//  hdl.c
//  mtx
//
//  Created by Pavel Morozkin on 24.01.14.
//  Copyright (c) 2014 Pavel Morozkin. All rights reserved.
//
#define _POSIX_C_SOURCE 199309L
#include "../include/api.h"
#include "../include/hdl.h"
#include "../include/buf.h"
#include <assert.h>

extern hdl_t hdl;

buf_t_ hdl_header(buf_t_ b, msg_t t)
{
  buf_t_ s = {};
	//buf_init(&s);

  switch (t) {
    case RFC:
    {
      ui64_t msg_id_ = get_current_time();
      buf_t_ msg_id = api.buf.add((ui8_t *)&msg_id_, 8);
      s = api.buf.cat(s, msg_id);
      ui32_t msg_data_len_ = b.size;
      buf_t_ msg_data_len = api.buf.add((ui8_t *)&msg_data_len_, 4);
      s = api.buf.cat(s, msg_data_len);
      s = api.buf.cat(s, b);

      break;
    }
    case API:
    {
      buf_t_ salt = shared_rc_get_salt();
      s = api.buf.cat(s, salt);
      buf_t_ session_id = shared_rc_get_ssid();
      s = api.buf.cat(s, session_id);
      ui64_t msg_id_ = get_current_time();
      buf_t_ msg_id = api.buf.add((ui8_t *)&msg_id_, 8);
      s = api.buf.cat(s, msg_id);
      ui32_t seqnh = shared_rc_get_seqnh();
      buf_t_ seq_no = api.buf.add_ui32(seqnh);
      s = api.buf.cat(s, seq_no);
      ui32_t msg_data_len_ = b.size;
      buf_t_ msg_data_len = api.buf.add((ui8_t *)&msg_data_len_, 4);
      s = api.buf.cat(s, msg_data_len);
      s = api.buf.cat(s, b);

      break;
    }
    default:
    {
      api.log.error("do not know this type");

      break;
    }
  }

  return s;
}

buf_t_ hdl_deheader(buf_t_ b, msg_t t)
{
  buf_t_ d;
	//buf_init(&d);

  switch (t) {
    case RFC:
    {
      // check msg_id diff (under construction...)
      // remove msg_id
      d = api.buf.add(b.data + 8, b.size - 8);
      ui32_t msg_data_len = api.buf.get_ui32(d);
      d.size -= 4;

      if (msg_data_len != d.size) {
        api.log.error("msg_data_len mismatch");
      }

      // remove len
      d = api.buf.add(d.data + 4, d.size);

      break;
    }
    case API:
    {
      // remove salt
      d = api.buf.add(b.data + 8, b.size - 8);
      // remove session_id
      d = api.buf.add(d.data + 8, d.size - 8);
      // save last msg_id
      shared_rc.last_msg_id = api.buf.add(d.data, 8);
      // remove message_id
      d = api.buf.add(d.data + 8, d.size - 8);
      // remove seq_no
      d = api.buf.add(d.data + 4, d.size - 4);
      ui32_t msg_data_len = api.buf.get_ui32(d);
      d.size -= 4;

      if (msg_data_len != d.size) {
        api.log.error("msg_data_len mismatch");
      }
      
      // remove len
      d = api.buf.add(d.data + 4, d.size);

      break;
    }
    case CTER:
    {
      // remove msg_id
      d = api.buf.add(b.data + 8, b.size - 8);
      // remove seq_no
      d = api.buf.add(d.data + 4, d.size - 4);
      ui32_t msg_data_len = api.buf.get_ui32(d);
      // remove len
      d = api.buf.add(d.data + 4, msg_data_len);

      break;
    }
    default:
    {
      break;
    }
  }

  return d;
}

#ifdef __GNUC__
#include <time.h>
#ifdef __MACH__
#include <mach/clock.h>
#include <mach/mach.h>
#define CLOCK_REALTIME 0
#define CLOCK_MONOTONIC 1
#endif

void my_clock_gettime(int clock_id, struct timespec * T)
{
#ifdef __MACH__
  // We are ignoring MONOTONIC and hope time doesn't go back to often
  clock_serv_t cclock;
  mach_timespec_t mts;
  host_get_clock_service(mach_host_self(), CALENDAR_CLOCK, &cclock);
  clock_get_time(cclock, &mts);
  mach_port_deallocate(mach_task_self(), cclock);
  T->tv_sec = mts.tv_sec;
  T->tv_nsec = mts.tv_nsec;
#else
  assert(clock_gettime(clock_id, T) >= 0);
#endif
}

//long long precise_time;
//long long precise_time_rdtsc;
//static __inline__ unsigned long long rdtsc(void)
//{
  //unsigned hi, lo;
  //__asm__ __volatile__("rdtsc" : "=a"(lo), "=d"(hi));

  //return ((unsigned long long)lo) | (((unsigned long long)hi) << 32);
//}

double get_utime(int clock_id)
{
  struct timespec T;
  my_clock_gettime(clock_id, &T);
  double res = T.tv_sec + (double) T.tv_nsec * 1e-9;

  //if (clock_id == CLOCK_REALTIME) {
    //precise_time = (long long)(res * (1LL << 32));
    //precise_time_rdtsc = rdtsc();
  //}

  return res;
}

long long get_current_time()
{
  return (long long)((1LL << 32) * get_utime(CLOCK_REALTIME)) & -4;
}

#elif defined _MSC_VER

long long get_current_time()
{
  return 0;
}

#endif
