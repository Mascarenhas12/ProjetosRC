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
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>

#define MSG_MAX_SIZE 4069
#define MSG_HEADER_MAX_SIZE 22

#define LOCALHOST "127.0.0.1"

int main(int argc, char const *argv[])
{
  fd_set readFds;
  fd_set writeFds;

  int clientSock;
  struct sockaddr_in clientSock_addr;
  struct hostent *host;

  char* message;

  char* inBuffer;
  char readChar;
  int inBuffer_size;

  int recvStatus;

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

  if ((host = gethostbyname(argv[1])) == NULL)
  {
    perror("Invalid server host name!");
    return -1;
  }
  clientSock_addr.sin_addr = *((struct in_addr *) host->h_addr);

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

  message = (char*) malloc(sizeof(char) * (MSG_HEADER_MAX_SIZE + MSG_MAX_SIZE + 1));
  inBuffer = (char*) malloc(sizeof(char) * (MSG_MAX_SIZE + 1));
  inBuffer_size = 0;

  while(1)
  {
    FD_ZERO(&readFds);
    FD_ZERO(&writeFds);

    FD_SET(0, &readFds);
    FD_SET(clientSock, &readFds);

    FD_SET(clientSock, &writeFds);

    /* int select(int nfds, fd_set *readfds, fd_set *writefds, fd_set *exceptfds, struct timeval *timeout); */
    if ((select(clientSock + 1, &readFds, &writeFds, 0, 0)) == -1)
    {
      perror("Client: Error while doing select!");
      return -1;
    }

    if (FD_ISSET(0, &readFds))
    {
      if ((recvStatus = read(0, &readChar, 1)) == -1)
      {
        perror("Client: Error while doing read!");
        return -1;
      }
      else if (recvStatus == 0)
      {
        break;
      }
      else if (readChar != '\n')
      {
        inBuffer[inBuffer_size] = readChar;
        inBuffer_size++;
      }
      else if (readChar == '\n')
      {
        if ((send(clientSock, inBuffer, MSG_MAX_SIZE + 1, 0)) == -1)
        {
          perror("Client: Error while doing send!");
          return -1;
        }
        bzero(inBuffer, inBuffer_size + 1);
        inBuffer_size = 0;
      }
    }

    if (FD_ISSET(clientSock, &readFds))
    {
      if ((recvStatus = recv(clientSock, message, MSG_MAX_SIZE + 1, 0)) == -1)
      {
        perror("Client: Error while doing recv!");
        return -1;
      }
      else if (recvStatus == 0)
      {
        break;
      }
      else
      {
        message = strtok(message, "\n");
        strcat(message, "\n");
      }

      if ((write(1, message, strlen(message))) == -1)
      {
        perror("Client: Error writing recieved message!");
        return -1;
      }
    }
  }

  close(clientSock);
  return 0;
}
