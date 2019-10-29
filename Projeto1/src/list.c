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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "list.h"

/* Function that inserts an integer into a list, given its head.
 * Insertion is at the beginning of the list.
 * Asymptotic complexity is O(1).
 * Returns a pointer to the inserted node so that the head can be updated.
 *
 * head - Pointer to the first element on the list
 * id   - Integer to be removed
 */
Link insertL(Link head, int id)
{
	Link new = (Link) malloc(sizeof(struct node));

	new->id = id;
	new->next = head;

	return new;
}

/* Function responsible for removing an integer from a list, given its head.
 * The node of the list is also freed from memory.
 *
 * head - Pointer to the first element on the list
 * id   - Integer to be removed
 */
void removeL(Link head, int id)
{
	Link t, u;

	for (u = NULL, t = head; t; u = t, t = t->next)
	{
		if (t->id == id)
		{
			if (u == NULL)
			{
				head = t->next;
			}
			else
			{
				u->next = t->next;
			}

			free(t);
			break;
		}
	}
}

/* Function that frees a list from memory, given its head.
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
		free(t);
	}
}
