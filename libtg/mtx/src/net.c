//
//  net.c
//  mtx
//
//  Created by Pavel Morozkin on 07.12.13.
//  Copyright (c) 2013 Pavel Morozkin. All rights reserved.
//

#include "../include/api.h"
#include "../include/net.h"
#include "../include/buf.h"

#include <string.h>
#include <sys/types.h>
#include <stdio.h>
#include <strings.h>

#ifdef __GNUC__
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>

net_t net_open(const _string_t ip, ui32_t port)
{
  net_t net;
  ui32_t error_code = 0;
  struct sockaddr_in serv_addr;
  struct hostent * server;

  net.sockfd = socket(AF_INET, SOCK_STREAM, 0);

  if (0 > net.sockfd) {
    error_code = 1;

    goto process_error;
  }

  server = gethostbyname(ip);

  if (0 == server) {
    error_code = 2;

    goto process_error;
  }

  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  bcopy((char *)server->h_addr_list[0], (char *)&serv_addr.sin_addr.s_addr, server->h_length);
  serv_addr.sin_port = htons(port);

  if (0 > connect(net.sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr))) {
    error_code = 3;

    goto process_error;
  }

process_error:
    switch (error_code) {
      case 1:
      {
        api.log.error("can't open socket");

        break;
      }
      case 2:
      {
        api.log.error("no such host");

        break;
      }
      case 3:
      {
        api.log.error("can't connect");

        break;
      }
      default:
      {
        break;
      }
    }

    shared_rc.net.sockfd = net.sockfd;
	
		// send intermediate protocol
		char init[] = {0xee, 0xee, 0xee, 0xee};
		send(net.sockfd, init, 4, 0);

    return net;
}

void net_close(net_t net)
{
  close(net.sockfd);
}

void net_send(const buf_t_ buf)
{
  net_t net = shared_rc_get_net();
  i32_t n = (i32_t)send(net.sockfd, buf.data, buf.size, 0);

  if (n < 0) {
    api.log.error("ERROR writing to socket");
  }
}

buf_t_ net_receive()
{
  buf_t_ buf;
	/*buf_init(&buf);*/
  net_t net = shared_rc_get_net();
  i32_t n = (i32_t)recv(net.sockfd, buf.data, max_buf_size, 0);

  if (n < 0) {
    api.log.error("ERROR reading from socket");
  }

  buf.size = n;

  return buf;
}

#elif defined _MSC_VER /*WIN32*/
#include <io.h>
#include <winsock.h>

SOCKET s;
net_t net_open(const string_t ip, ui32_t port)
{
  net_t n = {};
  WSADATA wsa;
  struct sockaddr_in server;

  if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) {
    //printf("Failed. Error Code : %d",WSAGetLastError());
  }

  if ((s = socket(AF_INET , SOCK_STREAM , 0)) == INVALID_SOCKET) {
    //printf("Could not create socket : %d" , WSAGetLastError());
  }

  server.sin_addr.s_addr = inet_addr(ip);
  server.sin_family = AF_INET;
  server.sin_port = htons(port);

  if (connect(s , (struct sockaddr *)&server , sizeof(server)) < 0) {
    //puts("connect error");
  }

  return n;
}

void net_close(const net_t net)
{
  closesocket(s);
}

void net_send(const buf_t_ buf)
{
  if (send(s , (const char *)buf.data , buf.size , 0) < 0) {
    //puts("Send failed");
  }
}

buf_t_ net_receive()
{
  buf_t_ buf;
  i32_t n = (i32_t)recv(s, (char *)buf.data, max_buf_size, 0);

  if (n < 0) {
    api.log.error("ERROR reading from socket");
  }

  buf.size = n;

  return buf;
}

#else
#error Do not know which socket model we will use
#endif

buf_t_ net_drive(const buf_t_ buf, stk_mode_t m)
{
  net_send(buf);
  buf_t_ r = {};
	/*buf_init(&r);*/

  switch (m) {
    case SEND_RECEIVE:
    {
      r = net_receive();

      break;
    }
    case SEND:
    {
      break;
    }
    default:
    {
      break;
    }
  }

  return r;
}
