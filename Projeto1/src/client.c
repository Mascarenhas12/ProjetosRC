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
#define LOCALHOST "127.0.0.1"

int main(int argc, char const *argv[])
{
  int clientSock;
  struct sockaddr_in clientSock_addr;

  char message[MAXCHAR+50];
  char buffer[MAXCHAR];

  if (argc < 3)
  {
    perror("Wrong number of arguments! Expected <server_host_name> <port_number>");
    return -1;
  }
  if (atoi(argv[2]) > 65535)
  {
    perror("Invalid port number!");
    return -1;
  }

  bzero((char *) &clientSock_addr, sizeof(clientSock_addr));
  clientSock_addr.sin_family = AF_INET;
  clientSock_addr.sin_port = htons(atoi(argv[2]));

  if (strcmp(argv[1], "localhost") == 0)
  {
    clientSock_addr.sin_addr.s_addr = inet_addr(LOCALHOST);
  }
  else if ((clientSock_addr.sin_addr.s_addr = inet_addr(argv[1])) == -1)
  {
    perror("Inavlid server host name!");
    return -1;
  }

  if ((clientSock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
  {
    perror("Error while creating client socket!");
    return -1;
  }

  if ((connect(clientSock, (struct sockaddr*) &clientSock_addr, sizeof(clientSock_addr))) == -1)
  {
    perror("Error doing connect in client!");
    return -1;
  }

  /*strcat(message, clientSock_addr.sin_addr.s_addr);
  strcat(message, ":");
  strcat(message, clientSock_addr.sin_port);
  strcat(message, "\0");*/

  while(1){

    /*if(write(1, message, sizeof(message)) == -1){
      perror("Error doing write");
      return -1;
    }*/

    read(0, message, sizeof(message));

    /*strcat(message,buffer);*/

    if ((send(clientSock, &message, sizeof(message), 0)) == -1)
    {
      perror("Error receiving from server!");
      return -1;
    }

    if ((recv(clientSock, &message, sizeof(message), 0)) == -1)
    {
      perror("Error receiving from server!");
      return -1;
    }

    write(1, message, sizeof(message));
  }

  close(clientSock);
  return 0;
}
