/* ================================================
 * IST LEIC-T Redes de Computadores 19/20
 * Project1 - list.h
 *
 * Authors:
 * Gonçalo Freire     - 90719
 * Manuel Mascarenhas - 90751
 * Miguel Levezinho   - 90756
 * ================================================
 */

#ifndef LIST_H
#define LIST_H
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
/* Abstraction of the node struct to a type Link */
typedef struct node *Link;
//typedef struct sockaddr_in *addr;

/* Struct that represents a node of a list of items */
struct node
{
	int fd;
	char* address;
	Link next;
};

Link insertL(Link head, int fd, struct sockaddr_in* address);

Link removeL(Link head, int fd);

void freeL(Link head);

#endif
