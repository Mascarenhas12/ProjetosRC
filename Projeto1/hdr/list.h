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

 /* Abstraction of the node struct to a type Link */
 typedef struct node *Link;

 /* Struct that represents a node of a list of items */
 struct node
 {
 	int id;
 	Link next;
 };

 Link insertL(Link head, int id);

 void removeL(Link head, int id);

 void freeL(Link head);

 #endif
