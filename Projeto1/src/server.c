/* ================================================
 * IST LEIC-T Redes de Computadores 19/20
 * Project1 - server.c
 *
 * Authors:
 * Gonçalo Freire     - 90719
 * Manuel Mascarenhas - 90751
 * Miguel Levezinho   - 90756
 * ================================================
 */

#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include "../hdr/server.h"
#include "../hdr/list.h"

#define MAXCHAR 4096

int main(int argc, char const *argv[])
{
  fd_set readFds;
  fd_set writeFds;

  int recvStatus;

  int numFD;
  int serverSock;
  int clientSock;
  Link clientSockList;
  Link t, u;

  struct sockaddr_in serverSock_addr;
  struct sockaddr_in clientSock_addr;
  socklen_t clientSock_addr_len;

  char message[MAXCHAR];
  char clientMsg;


  /* ======================================================================================== */
  /* Arguments verification and init                                                          */
  /* ======================================================================================== */


  /*1 - 1023 so pode correr em root duvida*/
  if (argc < 2)
  {
    perror("Wrong number of arguments! Expected <port_number>");
    return -1;
  }
  if (atoi(argv[1]) > 65535)
  {
    perror("Invalid port number!");
    return -1;
  }

  /* int socket(int domain, int type, int protocol); */
  if ((serverSock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
  {
    perror("Error while creating server socket!");
    return -1;
  }

  bzero((char *) &serverSock_addr, sizeof(serverSock_addr));
  serverSock_addr.sin_family = AF_INET;
  serverSock_addr.sin_port = htons(atoi(argv[1]));
  serverSock_addr.sin_addr.s_addr = htonl(INADDR_ANY);


  /* ======================================================================================== */
  /* Bind and listen                                                                          */
  /* ======================================================================================== */


  /* int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen); */
  if ((bind(serverSock, (struct sockaddr*) &serverSock_addr, sizeof(serverSock_addr))) == -1)
  {
    perror("Error while doing bind!");
    return -1;
  }

  /* int listen(int sockfd, int backlog); */
  printf("Listening on port: %s\n",argv[1]);
  if ((listen(serverSock, 1)) == -1)
  {
    perror("Error while doing listen!");
    return -1;
  }

  /* ======================================================================================== */
  /* Select and Accept                                                                        */
  /* ======================================================================================== */

  numFD = 1;
  clientSockList = NULL;

  while (1)
  {
    FD_ZERO(&readFds);
    FD_ZERO(&writeFds);

    FD_SET(serverSock, &readFds);
    FD_SET(serverSock, &writeFds);

    for (u = clientSockList; u != NULL; u = u->next)
    {
      FD_SET(u->id, &readFds);
      FD_SET(u->id, &writeFds);
    }
    /* int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout); */
    if ((select(numFD + 1, &readFds, &writeFds, 0, 0)) == -1)
    {
      perror("Error while doing select!");
      return -1;
    }

    if (FD_ISSET(serverSock, &readFds))
    {
      clientSock_addr_len = sizeof(clientSock_addr);
      if ((clientSock = accept(serverSock, (struct sockaddr*) &clientSock_addr, &clientSock_addr_len)) == -1)
      {
        perror("Error while doing accept!");
        return -1;
      }

      numFD++;
      clientSockList = insertL(clientSockList, clientSock);

      for (u = clientSockList; u != NULL; u = u->next)
      {
        if (FD_ISSET(u->id, &writeFds))
        {
          if ((send(t->id, message, sizeof(message), 0)) == -1)
          {
            perror("Error while sending message in server! (line 151)");
            return -1;
          }
        }
      }
      if ((send(1, message, sizeof(message), 0)) == -1)
      {
        perror("Error while sending message in server! (line 158)");
        return -1;
      }
    }

    for (u = clientSockList; u != NULL; u = u->next)
    {
      if (FD_ISSET(u->id, &readFds))
      {
        if ((recvStatus = recv(u->id, message, sizeof(message), 0)) == -1)
        {
          perror("Error while doing recv!");
          return -1;
        }
        else if (recvStatus == 0)
        {
          message = "Client left";
        }

        for (t = clientSockList; t != NULL; t = t->next)
        {
          if (FD_ISSET(t->id, &writeFds) && t->id != u->id)
          {
            if ((send(t->id, message, sizeof(message), 0)) == -1)
            {
              perror("Error while sending message in server! (line 183)");
              return -1;
            }
          }
        }
      }
    }
  }

  close(serverSock);

  return 0;
}
