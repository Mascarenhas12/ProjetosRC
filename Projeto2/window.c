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

window_t* create_w(int size, int max_seq_num)
{
	window_t* new = (window_t*) malloc(sizeof(window_t));

	new->size = size;
	new->max_seq_num = max_seq_num;
	new->scope = (int*) malloc(sizeof(int) * size);
	
	for (int i = 0; i < size; i++)
		new->scope[i] = i + 1;

	return new;
}

int get_base_w(window_t* W)
{
	return W->scope[0];
}

int contains_w(window_t* W, int seq_num, int circularLogic)
{
	if (seq_num >= W->scope[0] && seq_num <= W->scope[W->size-1])
		return 1;

	if (circularLogic)
		for (int i = 0; i < W->size; i++)
			if (W->scope[i] == seq_num)
				return 1;

	return 0;
}

void advance_w(window_t* W, int amount, int circularLogic)
{
	for (int i = 0; i < W->size; i++)
	{
		if (circularLogic && W->scope[i] == W->max_seq_num)
			W->scope[i] = 1;
		else
			W->scope[i] += 1;
	}
}

void print_w(window_t* W)
{
	printf("\n[");
	for (int i = 0; i < W->size - 1; i++)
	{
		printf("%d, ", W->scope[i]);
	}
	printf("%d]\n", W->scope[W->size - 1]);
}

void free_w(window_t* W)
{
	free(W->scope);
	free(W);
}








