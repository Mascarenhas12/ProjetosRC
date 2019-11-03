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

#define MSG_MAX_SIZE 4096
#define MSG_HEADER_MAX_SIZE 22

int main(int argc, char const *argv[])
{
  fd_set readFds;

  int clientSock;
  struct sockaddr_in clientSock_addr;
  struct hostent *host;

  char* message;

  char* inBuffer;
  char readChar;
  int inBuffer_size;

  int recvStatus;
  int exitStatus;

  /* ======================================================================================== */
  /* Argument verification and init                                                           */
  /* ======================================================================================== */

  if (argc < 3)
  {
    perror("Wrong number of arguments! Expected <server_host_name> <port_number>");
    exit(-1);
  }
  if (atoi(argv[2]) > 65535)
  {
    perror("Invalid port number!");
    exit(-1);
  }

  memset((char *) &clientSock_addr, 0, sizeof(clientSock_addr));
  clientSock_addr.sin_family = AF_INET;
  clientSock_addr.sin_port = htons(atoi(argv[2]));

  if ((host = gethostbyname(argv[1])) == NULL)
  {
    perror("Invalid server host name!");
    exit(-1);
  }
  clientSock_addr.sin_addr = *((struct in_addr *) host->h_addr);

  /* ======================================================================================== */
  /* Create socket and connect to server                                                      */
  /* ======================================================================================== */

  if ((clientSock = socket(AF_INET, SOCK_STREAM, 0)) == -1)
  {
    perror("Error while creating client socket!");
    exit(-1);
  }

  if ((connect(clientSock, (struct sockaddr*) &clientSock_addr, sizeof(clientSock_addr))) == -1)
  {
    perror("Error doing connect in client!");
    close(clientSock);
    exit(-1);
  }

  message = (char*) malloc(sizeof(char) * (MSG_HEADER_MAX_SIZE + MSG_MAX_SIZE + 1));
  inBuffer = (char*) malloc(sizeof(char) * (MSG_MAX_SIZE + 100));
  inBuffer_size = 0;
  exitStatus = 0;

  /* ======================================================================================== */
  /* Select and read/send cicle                                                               */
  /* ======================================================================================== */

  while(1)
  {
    FD_ZERO(&readFds);
    FD_SET(0, &readFds);
    FD_SET(clientSock, &readFds);

    if ((select(clientSock + 1, &readFds, 0, 0, 0)) == -1)
    {
      perror("chat-client:Error while doing select!");
      exitStatus = -1;
      break;
    }

    /* ======================================================================================== */
    /* Check for input from stdin                                                               */
    /* ======================================================================================== */

    if (FD_ISSET(0, &readFds))
    {
      if ((recvStatus = read(0, &readChar, 1)) == -1)
      {
        perror("chat-client:Error while doing read!");
        exitStatus = -1;
        break;
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
        inBuffer[inBuffer_size] = readChar;
        inBuffer_size++;

        if ((send(clientSock, inBuffer, inBuffer_size, 0)) == -1)
        {
          perror("chat-client:Error while doing send!");
          exitStatus = -1;
          break;
        }
        memset(inBuffer, 0, MSG_MAX_SIZE + 100);
        inBuffer_size = 0;
      }
    }

    /* ======================================================================================== */
    /* Check for sent messages from the server and write them on stdout                         */
    /* ======================================================================================== */

    if (FD_ISSET(clientSock, &readFds))
    {
      if ((recvStatus = read(clientSock, message, MSG_HEADER_MAX_SIZE + MSG_MAX_SIZE + 1)) == -1)
      {
        perror("chat-client:Error while doing recv!");
        exitStatus = -1;
        break;
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
        perror("chat-client:Error writing recieved message!");
        exitStatus = -1;
        break;
      }
      memset(message, 0, MSG_HEADER_MAX_SIZE + MSG_MAX_SIZE + 1);
    }
  }

  free(message);
  free(inBuffer);
  close(clientSock);

  exit(exitStatus);
}
