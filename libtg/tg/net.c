/**
 * File              : net.c
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 21.11.2024
 * Last Modified Date: 15.01.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "../tg/tg.h"
#include <stdint.h>
#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <unistd.h>
#include "../tg/list.h"
#include "../tl/alloc.h"
#include "queue.h"
#include "transport.h"
#include "net.h"

int tg_net_open(tg_t *tg, const char *ip, int port)
{
  struct sockaddr_in serv_addr;
  struct hostent * server;
	int sockfd;

  sockfd = 
		socket(AF_INET, SOCK_STREAM, 0);

  if (sockfd < 0) {
		ON_ERR(tg, "%s: can't open socket", __func__);
    return -1;
  }

  server = gethostbyname(ip);
 
  if (server == 0) {
		ON_ERR(tg, "%s: no host with ip: '%s'", __func__, ip);
    return -1;
  }

  bzero((char *) &serv_addr, sizeof(serv_addr));
  serv_addr.sin_family = AF_INET;
  bcopy(
			(char *)server->h_addr_list[0],
		 	(char *)&serv_addr.sin_addr.s_addr,
		 	server->h_length);
  serv_addr.sin_port = htons(port);

  if (connect(
				sockfd, 
				(struct sockaddr *) &serv_addr, 
				sizeof(serv_addr)) < 0) 
	{
    ON_ERR(tg, "%s: can't connect", __func__);
    return -1;
  }

	// send intermediate protocol
	char init[] = {0xee, 0xee, 0xee, 0xee};
	send(sockfd, init, 4, 0);

	return sockfd;
}

void tg_net_close(tg_t *tg, int sockfd)
{
  close(sockfd);
}
