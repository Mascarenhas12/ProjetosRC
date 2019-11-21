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

    struct timeval timeout;      
    timeout.tv_sec = 1;
    timeout.tv_usec = 0;
    
    int port;
    int senderSock;
    int receiverSock;
    struct sockaddr_in senderSock_addr;
    struct sockaddr_storage receiverSock_addr;
	socklen_t receiverSock_addr_len;
    
    int window_size = argv[4];
    long array_size = (GetFileSize(argv[1]) % 1000) + 1;// vamos ver o numero de chunks que vamos enviar
    unsigned char aux_buffer[1000];
    data_pkt_t file_to_send[array_size];

    if (argc < 4)
	{
		perror("file-receiver:Wrong number of arguments! <file> <port> <window_size>");
		exit(-1);
	}

    
	if ((port = atoi(argv[3])) > 65535)
	{
		perror("file-receiver:Invalid port number!");
		exit(-1);
	}

    if (atoi(argv[4]) > MAX_WINDOW_SIZE)
	{
		perror("file-receiver:Invalid window size!");
		exit(-1);
	}
    
    f = fopen(filename, "rb");
    if (f == NULL) return -1;

    for(int i = 0; i < array_size; i++){//inicializar o vetor
        data_pkt_t.seq_num = i+1;
        fread(aux_buffer, 1000, 1, f);
        data_pkt_t.data = aux_buffer;
        bzero(aux_buffer, 1000);
    }

    if ((senderSock = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
	{
		perror("file-receiver:Error creating receiver socket!");
		exit(-1);
	}

    if (setsockopt (sockfd, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout,sizeof(timeout)) < 0){
        error("setsockopt failed\n");
    }
    memset(&receiverSock_addr, 0, sizeof(senderSock_addr));
	receiverSock_addr_len = sizeof(struct sockaddr_storage);

	memset(&senderSock_addr, 0, sizeof(senderSock_addr));
	senderSock_addr.sin_family = AF_INET;
	senderSock_addr.sin_port = htons(port);
	senderSock_addr.sin_addr.s_addr = INADDR_ANY;

    if ((host = gethostbyname(argv[2])) == NULL)
    {
        perror("Invalid server host name!");
        exit(-1);
    }

    for( i = 0; i < array_size; i++){

        if (sendto(senderSock,(data_pkt_t*) file_to_send[i]  , sizeof(data_pkt_t), 0, (struct sockaddr*) &receiverSock_addr, &receiverSock_addr_len) == -1)
	    {
		    perror("file-receiver:Error while sending ACK!");
		    close(receiverSock);
		    exit(-1);
	    }

        if ((n = recvfrom(senderSock, (ack_pkt_t*) ack , sizeof(ack_pkt_t), 0, (struct sockaddr*) &receiverSock_addr, &receiverSock_addr_len)) == -1)
	    {
		perror("file-receiver:Error while receiving!");
		close(receiverSock);
		exit(-1);
	    }

    }

    exit(0);
}
