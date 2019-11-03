/* ================================================
 * IST LEIC-T Redes de Computadores 19/20
 * Project1 - list.c
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
#include <sys/socket.h>

#include "list.h"

/* Function that inserts client info into a list, given its head.
 * Insertion is at the beginning of the list.
 * Returns a pointer to the inserted node so that the head can be updated.
 *
 * head    - Pointer to the first element on the list
 * fd      - File discriptor for the inserted clients socket
 * address - Address of the client, from which the port number and IP address are derived
 */
Link insertL(Link head, int fd, struct sockaddr_in* address)
{
	Link new = (Link) malloc(sizeof(struct node));

	new->fd = fd;
	new->address = (char*) malloc(sizeof(char) * 25);
	sprintf(new->address, "%s:%d", inet_ntoa((struct in_addr) address->sin_addr), htons(address->sin_port));

	new->next = head;

	return new;
}

/* Function responsible for removing a client from the client socket list, given its head.
 * The node of the list is freed from memory and the clients socket closed.
 *
 * head - Pointer to the first element on the list
 * fd   - File descriptor of the client that disconnected
 */
Link removeL(Link head, int fd)
{
	Link t, u;
	for (u = NULL, t = head; t; u = t, t = t->next)
	{
		if (t->fd == fd)
		{
			if (u == NULL)
			{
				head = t->next;
			}
			else
			{
				u->next = t->next;
			}

			close(fd);
			free(t->address);
			free(t);
			break;
		}
	}
	return head;
}

/* Function that frees the client socket list from memory, given its head.
 *
 * head - Pointer to the first element on the list
 */
void freeL(Link head)
{
	Link t;

	while (head != NULL)
	{
		t = head;
		head = t->next;

		close(t->fd);
		free(t->address);
		free(t);
	}
}
