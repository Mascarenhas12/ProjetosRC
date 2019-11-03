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
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include "list.h"

#define MSG_MAX_SIZE 4096
#define MSG_HEADER_MAX_SIZE 22

/* Function that closes allocated resources.
 *
 * status         - exit status (-1 if error)
 * serverSock     - Socket the server uses to accept client connections
 * clientSockList - List of clients connected
 * message        - Message buffer
 */
static int close_server(int status, int serverSock, Link clientSockList, char* message)
{
  freeL(clientSockList);
  close(serverSock);
  free(message);

  exit(status);
}

/* Function that retrieves a message sent by a client.
 * Returns -1 if the retrival process fails, the clients FD if the client left, or 1 if a written message was sent.
 *
 * clientSock      - Client socket
 * clientSock_addr - Address of the client (port and IP) to prepend to the message
 * buffer          - Buffer that will store the message to be sent after function returns
 */
static int getMessage(int clientSock, char* clientSock_addr, char* buffer)
{
  int recvStatus;
  char* recvMsg = (char*) malloc(sizeof(char) * (MSG_MAX_SIZE + 1));
  memset(recvMsg, 0, MSG_MAX_SIZE + 1);

  if ((recvStatus = read(clientSock, recvMsg, MSG_MAX_SIZE + 1)) == -1)
  {
    perror("chat-server:Error recieving client message!");
    return -1;
  }
  else if (recvStatus != 0)
  {
    recvStatus = 1;
    sprintf(buffer, "%s %s", clientSock_addr, recvMsg);
  }
  else
  {
    recvStatus = clientSock;
    sprintf(buffer, "%s left.\n", clientSock_addr);
  }

  free(recvMsg);
  return recvStatus;
}

int main(int argc, char const *argv[])
{
  fd_set readFds;

  int recvStatus;

  int numFD;
  int serverSock;
  int clientSock;
  Link clientSockList;
  Link t, u;

  struct sockaddr_in serverSock_addr;
  struct sockaddr_in clientSock_addr;
  socklen_t clientSock_addr_len;

  char* message;

  /* ======================================================================================== */
  /* Argument verification and init                                                           */
  /* ======================================================================================== */

  if (argc < 2)
  {
    perror("Wrong number of arguments! Expected <port_number>");
    exit(-1);
  }
  if (atoi(argv[1]) > 65535)
  {
    perror("Invalid port number!");
    exit(-1);
  }

  if ((serverSock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
  {
    perror("chat-server:Error while creating server socket!");
    exit(-1);
  }

  memset((char *) &serverSock_addr, 0, sizeof(serverSock_addr));
  serverSock_addr.sin_family = AF_INET;
  serverSock_addr.sin_port = htons(atoi(argv[1]));
  serverSock_addr.sin_addr.s_addr = INADDR_ANY;

  /* ======================================================================================== */
  /* Bind and listen                                                                          */
  /* ======================================================================================== */

  setsockopt(serverSock, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int));

  if ((bind(serverSock, (struct sockaddr*) &serverSock_addr, sizeof(serverSock_addr))) == -1)
  {
    perror("chat-server:Error while doing bind!");
    close(serverSock);
    exit(-1);
  }

  printf("Listening on port: %s\n", argv[1]);

  if ((listen(serverSock, 1000)) == -1)
  {
    perror("chat-server:Error while doing listen!");
    close(serverSock);
    exit(-1);
  }

  /* ======================================================================================== */
  /* Select and accept                                                                        */
  /* ======================================================================================== */

  numFD = serverSock;
  clientSockList = NULL;
  message = (char*) malloc(sizeof(char) * (MSG_HEADER_MAX_SIZE + MSG_MAX_SIZE + 1));

  while (1)
  {
    FD_ZERO(&readFds);
    FD_SET(serverSock, &readFds);

    for (u = clientSockList; u != NULL; u = u->next)
    {
      FD_SET(u->fd, &readFds);
    }

    if ((select(numFD + 1, &readFds, 0, 0, 0)) == -1)
    {
      if (errno == EINTR)
      {
        continue;
      }
      perror("chat-server:Error while doing select!");
      exit(-1);
    }

    /* ======================================================================================== */
    /* Check for clients joining the server and notify                                          */
    /* ======================================================================================== */

    if (FD_ISSET(serverSock, &readFds))
    {
      clientSock_addr_len = sizeof(clientSock_addr);
      if ((clientSock = accept(serverSock, (struct sockaddr*) &clientSock_addr, &clientSock_addr_len)) == -1)
      {
        perror("chat-server:Error while doing accept!");
        close_server(-1, serverSock, clientSockList, message);
      }

      if (numFD < clientSock)
      {
        numFD = clientSock;
      }

      clientSockList = insertL(clientSockList, clientSock, &clientSock_addr);

      for (u = clientSockList; u != NULL; u = u->next)
      {
        sprintf(message, "%s joined.\n", clientSockList->address);

        if ((send(u->fd, message, strlen(message), 0)) == -1)
        {
          perror("chat-server:Error while sending join message to clients!");
          close_server(-1, serverSock, clientSockList, message);
        }
      }
      if ((write(1, message, strlen(message))) == -1)
      {
        perror("chat-server:Error while writing join message on stdout!");
        close_server(-1, serverSock, clientSockList, message);
      }
      memset(message, 0, MSG_HEADER_MAX_SIZE + MSG_MAX_SIZE + 1);
    }

    /* ======================================================================================== */
    /* Check for sent messages from the clients and redirect them                               */
    /* ======================================================================================== */

    recvStatus = 1;

    for (u = clientSockList; u != NULL; u = u->next)
    {
      if (recvStatus > 1)
      {
        clientSockList = removeL(clientSockList, recvStatus);

        if (numFD == recvStatus)
        {
          numFD--;
        }
      }

      if (FD_ISSET(u->fd, &readFds))
      {
        memset(message, 0, MSG_HEADER_MAX_SIZE + MSG_MAX_SIZE + 1);
        recvStatus = getMessage(u->fd, u->address, message);

        for (t = clientSockList; t != NULL; t = t->next)
        {
          if (t->fd != u->fd)
          {
            if (((send(t->fd, message, strlen(message), 0)) == -1))
            {
              perror("chat-server:Error while sending a message to clients!");
              close_server(-1, serverSock, clientSockList, message);
            }
          }
        }

        if ((write(1, message, strlen(message))) == -1)
        {
          perror("chat-server:Error while writing a message on stdout!");
          close_server(-1, serverSock, clientSockList, message);
        }
        memset(message, 0, MSG_HEADER_MAX_SIZE + MSG_MAX_SIZE + 1);
      }
    }

    if (recvStatus > 1)
    {
      clientSockList = removeL(clientSockList, recvStatus);

      if (numFD == recvStatus)
      {
        numFD--;
      }
    }
  }
}
