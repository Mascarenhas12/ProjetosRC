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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/types.h>
#include "../hdr/server.h"
#define MAXCHAR 4096

int main(int argc, char const *argv[]) {

  fd_set readFds;
  fd_set writeFds;

  int sockFd;
  int clientFd;

  struct sockaddr sockAddr;

  if ((sockFd = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) { /* int socket(int domain, int type, int protocol); */
    perror("Error while doing select!");
    return -1;
  }

  if ((bind(sockFd, &sockAddr, )) == -1) { /* int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen); */
    perror("Error while doing bind!");
    return -1;
  }

  if ((listen(sockFd, )) == -1) {
    perror("Error while doing listen!");
    return -1;
  }

  FD_ZERO(&readFds);
  FD_ZERO(&writeFds);

  FD_SET(fileDescriptor, &readFds);
  FD_SET(fileDescriptor, &write);

  /* select code */

  /*FD_ISSET()*/

  if ((clientFd = accept(sockFd, , )) == -1) {
    perror("Error while doing accept!");
    return -1;
  }








  return 0;
}
