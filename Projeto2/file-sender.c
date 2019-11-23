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
#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include "packet-format.h"


data_pkt_t createDataPacket(char* data, uint32_t last_seq){
	data_pkt_t new;

	sprintf(new.data,"%s",data);
	new.seq_num = ++last_seq;

	return new;
}

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
    struct sockaddr_in receiverSock_addr;
	socklen_t receiverSock_addr_len;
    
    FILE *f;
    int seq = 1;
    int index = 0;
    int number_of_bytes = 0;

    //int window_size = atoi(argv[4]);
    long array_size = (GetFileSize(argv[1]) % 1000) + 1;// vamos ver o numero de chunks que vamos enviar
    unsigned char aux_buffer[1000];
    data_pkt_t file_to_send[array_size];
    ack_pkt_t ack;

    if (argc != 4) 
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
    
    f = fopen(argv[1], "rb");
    if (f == NULL) return -1;

    for(int i = 0; i < array_size; i++){//inicializar o vetor
        number_of_bytes	= fread(aux_buffer, 1000, 1, f);
        memcpy(file_to_send[i].data, aux_buffer, number_of_bytes);
        bzero(aux_buffer, number_of_bytes);
    }

    fclose(f);

    if ((senderSock = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
	{
		perror("file-receiver:Error creating receiver socket!");
		exit(-1);
	}

    if (setsockopt (senderSock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout,sizeof(timeout)) < 0){
        perror("setsockopt failed\n");
    }
    memset(&receiverSock_addr, 0, sizeof(receiverSock_addr));
	receiverSock_addr_len = sizeof(struct sockaddr_in);

	memset(&receiverSock_addr, 0, sizeof(receiverSock_addr));
	receiverSock_addr.sin_family = AF_INET;
	receiverSock_addr.sin_port = htons(port);
	receiverSock_addr.sin_addr.s_addr = inet_addr(argv[1]);

    while(index < array_size){

    	file_to_send[index].seq_num = seq;

        if (sendto(senderSock, (data_pkt_t*) &file_to_send[index], sizeof(file_to_send[index]), 0, (struct sockaddr*) &receiverSock_addr, receiverSock_addr_len) == -1)
	    {
		    perror("file-receiver:Error while sending ACK!");
		    close(senderSock);
		    exit(-1);
	    }

        if ((recvfrom(senderSock, &ack, sizeof(ack_pkt_t), 0, (struct sockaddr*) &receiverSock_addr, &receiverSock_addr_len)) == -1)
	    {
		    if(errno == (EAGAIN || EWOULDBLOCK)){
                seq++;
                continue;
            }
            
            perror("file-receiver:Error while receiving!");
		    close(senderSock);
		    exit(-1);
	    }

        index++;
        seq++;
    }

    exit(0);
}
