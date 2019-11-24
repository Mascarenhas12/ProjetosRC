/* ================================================
 * IST LEIC-T Redes de Computadores 19/20
 * Project2 - window.h
 *
 * Authors:
 * Gonçalo Freire     - 90719
 * Manuel Mascarenhas - 90751
 * Miguel Levezinho   - 90756
 * ================================================
 */

#ifndef WINDOW_H
#define WINDOW_H

typedef struct window {
	int* scope;
	int size;
	int max_seq_num;
} window_t;

window_t* create_w(int size, int max_seq_num);

int get_base_w(window_t* W);

int contains_w(window_t* W, int seq_num, int circularLogic);

void advance_w(window_t* W, int amount, int circularLogic);

void print_w(window_t* W);

void free_w(window_t* W);

#endif