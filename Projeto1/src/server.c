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

#define MAXCHAR 4096

int main(int argc, char const *argv[])
{
  int serverPort;

  /* fd_set readFds; */
  /* fd_set writeFds; */

  int fd_serverSock;
  int fd_clientSock;

  struct sockaddr_in serverSock_addr;
  struct sockaddr_in clientSock_addr;
  socklen_t clientSock_addr_len;

  /*char message[MAXCHAR] = "Connected to server!";*/
  char message[MAXCHAR];

  /*1 - 1023 so pode correr em root duvida*/
  if (argc < 2 || atoi(argv[1]) > 65535)
  {
    perror("Wrong arguments! Expected a server port!");
    return -1;
  }

  serverPort = atoi(argv[1]);

  /* int socket(int domain, int type, int protocol); */
  if ((fd_serverSock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
  {
    perror("Error while creating server socket!");
    return -1;
  }

  bzero((char *) &serverSock_addr, sizeof(serverSock_addr));
  serverSock_addr.sin_family = AF_INET;
  serverSock_addr.sin_port = htons(serverPort);
  serverSock_addr.sin_addr.s_addr = htonl(INADDR_ANY);

  /* int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen); */
  if ((bind(fd_serverSock, (struct sockaddr*) &serverSock_addr, sizeof(serverSock_addr))) == -1)
  {
    perror("Error while doing bind!");
    return -1;
  }

  /* int listen(int sockfd, int backlog); */
  if ((listen(fd_serverSock, 1)) == -1)
  {
    perror("Error while doing listen!");
    return -1;
  }
  /*
  FD_ZERO(&readFds);
  FD_ZERO(&writeFds);

  FD_SET(fileDescriptor, &readFds);
  FD_SET(fileDescriptor, &write);
  */
  /* select code */

  /*FD_ISSET()*/

  clientSock_addr_len = sizeof(clientSock_addr);
  if ((fd_clientSock = accept(fd_serverSock, (struct sockaddr*) &clientSock_addr, &clientSock_addr_len)) == -1)
  {
    perror("Error while doing accept!");
    return -1;
  }

  while(1){
    /* ssize_t send(int sockfd, const void *buf, size_t len, int flags); */
    
    if(scanf("%s",message)==-1){

    	printf("Scanf error");
    	return -1;
    }
    
    if ((send(fd_clientSock, message, sizeof(message), 0)) == -1)
    {
      perror("Error while sending message in server!");
      return -1;
    }
  }

  close(fd_serverSock);

  return 0;
}
