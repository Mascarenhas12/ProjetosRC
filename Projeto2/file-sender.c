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

typedef struct chunck_aux {
    data_pkt_t chunck;
    int ack;
    int timeout;
} chunck_aux


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

    int window_size = 1;//por agora

    long array_size = (GetFileSize(argv[1]) % 1000) + 1;// vamos ver o numero de chunks que vamos enviar

    unsigned char aux_buffer[1000];

    chunck_aux file_to_send[array_size];

    f = fopen(filename, "rb");
    if (f == NULL) return -1;

    for(int i = 0; i < array_size; i++){//inicializar o vetor
        file_to_send[i].chunck.seq_num = 1;
        file_to_send[i].ack = 0;
        file_to_send[i].timeout = 0;
        fread(aux_buffer, 1000, 1, f);
        file_to_send[i].chunck.data = aux_buffer;
        bzero(aux_buffer, 1000);
    }

    

}

