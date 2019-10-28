/* ================================================
 * IST LEIC-T Redes de Computadores 19/20
 * Project1 - client.c
 *
 * Authors:
 * Gonçalo Freire     - 90719
 * Manuel Mascarenhas - 90751
 * Miguel Levezinho   - 90756
 * ================================================
 */

#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include "../hdr/server.h"

#define MAXCHAR 4096

int main(int argc, char const *argv[])
{
  int fd_clientSock;

  int clientPort;
  char clientAddr[256] = "127.0.0.1";

  struct sockaddr_in clientSock_addr;

  char buffer[MAXCHAR];

  if (argc < 3 || strcmp(argv[1], "localhost") || atoi(argv[2]) > 65535)
  {
    perror("Wrong arguments! Expected a server port!");
    return -1;
  }

  /*clientAddr = "127.0.0.1";*/
  clientPort = atoi(argv[2]);

  if ((fd_clientSock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
  {
    perror("Error while creating client socket!");
    return -1;
  }

  bzero((char *) &clientSock_addr, sizeof(clientSock_addr));
  clientSock_addr.sin_family = AF_INET;
  clientSock_addr.sin_port = htons(clientPort);
  clientSock_addr.sin_addr.s_addr = inet_addr(clientAddr);

  if ((connect(fd_clientSock, (struct sockaddr*) &clientSock_addr, sizeof(clientSock_addr))) == -1)
  {
    perror("Error doing connect in client!");
    return -1;
  }

  printf("%s\n");

  while(1){
    
    if ((recv(fd_clientSock, &buffer, sizeof(buffer), 0)) == -1)
    {
      perror("Error receiving from server!");
      return -1;
    }

    printf("%s\n", buffer);

  }

  close(fd_clientSock);
  return 0;
}
