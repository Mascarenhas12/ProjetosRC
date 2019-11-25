/* ================================================
 * IST LEIC-T Redes de Computadores 19/20
 * Project2 - window.c
 *
 * Authors:
 * Gonçalo Freire     - 90719
 * Manuel Mascarenhas - 90751
 * Miguel Levezinho   - 90756
 * ================================================
 */

#include <stdio.h>
#include <stdlib.h>

#include "window.h"

#define MIN(a, b) (a < b ? a : b)

/* Function that creates a new window type.
 * The window scope is initialized with crescent sequence numbers starting at 1.
 * Returns a pointer to the struct representing the window.
 * size           - Size of the scope of the window
 * max_seq_num    - The largest sequence number that can appear in the window. If set to -1 window is infinite
 * circular_logic - Flag set if the sequence numbers repeat after max_seq_num is reached
 */
window_t* create_w(int size, int max_seq_num, int circular_logic)
{
	window_t* new = (window_t*) malloc(sizeof(window_t));

	if (max_seq_num != -1 && size > max_seq_num)
		new->size = max_seq_num;
	else
		new->size = size;

	new->max_seq_num = max_seq_num;
	new->scope = (int*) malloc(sizeof(int) * new->size);
	new->circular_logic = circular_logic;

	for (int i = 0; i < new->size; i++)
		new->scope[i] = i + 1;

	return new;
}

/* Function that returns the base of the window.
 * W - Window to get the base from
 */
int get_base_w(window_t* W)
{
	return W->scope[0];
}

/* Function that returns the size of the window.
 * W - Window to get the size from
 */
int get_size_w(window_t* W)
{
	return W->size;
}

/* Function that checks if a certain sequence number is whitin the scope of a window.
 * Returns 1 if whitin and 0 otherwise.
 * W       - Window to check
 * seq_num - Sequence number to find
 */
int contains_w(window_t* W, int seq_num)
{
	if (seq_num >= W->scope[0] && seq_num <= W->scope[W->size-1])
		return 1;

	if (W->circular_logic)
		for (int i = 0; i < W->size; i++)
			if (W->scope[i] == seq_num)
				return 1;

	return 0;
}

static int can_reduce_w(window_t* W, int seq_num)
{
	return W->max_seq_num != -1 && seq_num > W->max_seq_num;
}

/* Function that advances the window.
 * Returns the new window base or -1 if window reached its set end.
 * W      - Window to advance
 * amount - Amount to advance the window
 */
int advance_w(window_t* W, int amount)
{
	for (int i = 0; i < W->size; i++)
	{
		W->scope[i] += amount;

		if (can_reduce_w(W, W->scope[i])) // Does not account circular logic
		{
			W->size -= (W->size - i);
			return W->size == 0 ? (W->scope[0] = -1) : W->scope[0];
		}

		if (W->circular_logic && W->scope[i] == W->max_seq_num)
		{
			W->scope[i] %= W->max_seq_num;
			if (W->scope[i] == 0)
			{
				W->scope[i] = 1;
			}
		}
	}
	return W->scope[0];
}

/* Function that checks if a window is empty.
 * Returns true if empty and false otherwise.
 * W - Window to check
 */
int empty_w(window_t* W)
{
	return W->size == 0;
}

/* Function that prints a formated form of the scope of the window.
 * W - Window to print
 */
void print_w(window_t* W)
{
	printf("[");
	for (int i = 0; i < W->size - 1; i++)
	{
		printf("%d, ", W->scope[i]);
	}
	if (!empty_w(W))
		printf("%d]\n", W->scope[W->size - 1]);
	else
		printf("]\n");
}

/* Function that frees all resources associated with a window.
 * W - Window to free
 */
void free_w(window_t* W)
{
	free(W->scope);
	free(W);
}
