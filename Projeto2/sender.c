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

#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include "chuck_aux.h"

long GetFileSize(const char* filename)
{
    long size;
    FILE *f;
 
    f = fopen(filename, "rb");
    if (f == NULL) return -1;
    fseek(f, 0, SEEK_END);
    size = ftell(f);
    fclose(f);
 
    return size;
}

int main(int argc, char const *argv[]){

    if (argc < 4)
	{
		perror("file-receiver:Wrong number of arguments! <file> <port> <window_size>");
		exit(-1);
	}

    int window_size = 1;//por agora

    long array_size = (GetFileSize(argv[1]) % 1000) + 1;// vamos ver o numero de chunks que vamos enviar

    unsigned char aux_buffer[1000];

    data_pkt_t file_to_send[array_size];

    f = fopen(filename, "rb");
    if (f == NULL) return -1;

    for(int i = 0; i < array_size; i++){//inicializar o vetor
        data_pkt_t.seq_num = i+1;
        fread(aux_buffer, 1000, 1, f);
        data_pkt_t.data = aux_buffer;
        bzero(aux_buffer, 1000);
    }



}

