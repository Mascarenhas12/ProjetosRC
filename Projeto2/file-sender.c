/* ================================================
 * IST LEIC-T Redes de Computadores 19/20
 * Project2 - file-sender.c
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

#define MAX_CHUNK_SIZE 1000

typedef struct  data_info
{
  int seq;
  int ack;
  int send;

}data_info;

data_pkt_t createDataPacket(char* data, int number_of_bytes, uint32_t last_seq){
	data_pkt_t new;
  //last_seq = (last_seq + 1) % 64;
  //new.seq_num = last_seq == 0 ? 64 : last_seq;
  new.seq_num = ++last_seq;
	memcpy(new.data, data, number_of_bytes);

	return new;
}

void give_ack(ack_pkt_t ack, data_info* chunks_info, int index, int window_size){
  //Se o seq_num recebido for igual ao do chunck i significa que esse foi recebido
  for(int i = index; i < index + window_size; i++){
    if(chunks_info[i].seq + 1 == ack.seq_num){
      chunks_info[i].ack = 1;//Chunck recebido
    }
  }
}

void move_window(int* index, data_info* chunks_info, int* counter){
  //Enquanto a base da window tiver sido recebida pode-mos mexe-la
  while(chunks_info[*index].ack == 1){
    //Podemos mandar mais menssagens
    (*counter) = (*counter) - 1;
    (*index) = (*index) + 1;
  }
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

    FILE *f;

    int port;

    int senderSock;

    struct sockaddr_in receiverSock_addr;

    socklen_t receiverSock_addr_len;

    int number_of_bytes = 0;


    int index = 0;//Numero do chunck em que estamos

    int counter = 0;//Numero de chunks que vamos enviar

    int window_size = atoi(argv[4]);

    long array_size = (GetFileSize(argv[1]) / MAX_CHUNK_SIZE) + 1;// vamos ver o numero de chunks que vamos enviar

    char aux_buffer[MAX_CHUNK_SIZE];//Vetor aux para passar do ficheiro para o packet
		memset(aux_buffer,0,MAX_CHUNK_SIZE);//Limpar o vetor

    data_pkt_t file_to_send[array_size];//Vetor com os chunks que vamos enviar

    data_info chunks_info[array_size];//Vetor com informacoes uteis sobre os chuncks co

    ack_pkt_t ack;//Oque que vamos receber

    if (argc != 5)
	{
		perror("file-sender:Wrong number of arguments! <file> <host> <port> <window_size>");
		exit(-1);
	}

	if (array_size <= 0){
		perror("file-sender:Erro a abrir o ficheiro");
		exit(-1);
	}

	if ((port = atoi(argv[3])) > 65535)
	{
		perror("file-receiver:Invalid port number!");
		exit(-1);
	}

  if (atoi(argv[4]) > MAX_WINDOW_SIZE)
	{
		perror("file-sender:Invalid window size!");
		exit(-1);
	}

  f = fopen(argv[1], "rb");
  if (f == NULL) return -1;


  //Inicializar o file_to_send e chunks_info:
  for(int i = 0; i < array_size; i++){
		if((number_of_bytes = fread(aux_buffer, 1, MAX_CHUNK_SIZE, f)) == -1){

      perror("file-sender:Error reading from file!");
        exit(-1);
    }
    file_to_send[i] = createDataPacket(aux_buffer,number_of_bytes,i);
    file_to_send[i].data[number_of_bytes] = '\0';
    memset(aux_buffer,0,sizeof(aux_buffer));
    chunks_info[i].ack = 0;
    chunks_info[i].send = 0;
    chunks_info[i].seq = file_to_send[i].seq_num;

    }

  fclose(f);

  if ((senderSock = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
	{
		perror("file-sender:Error creating receiver socket!");
		exit(-1);
	}

  //Set up do timer no socket
  if (setsockopt (senderSock, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeout,sizeof(timeout)) < 0){
    perror("file-sender:setsockopt failed\n");
  }
	receiverSock_addr_len = sizeof(struct sockaddr_in);

	memset(&receiverSock_addr, 0, sizeof(receiverSock_addr));
	receiverSock_addr.sin_family = AF_INET;
	receiverSock_addr.sin_port = htons(port);
	receiverSock_addr.sin_addr.s_addr = INADDR_ANY;

  while(index < array_size){
    while(counter < window_size){
      //Enviamos menssagem enquanto tivermos espaco e se ja nao tiver sido enviada
      if(index + counter == array_size) break;

      if(chunks_info[index + counter].send == 0){
        if (sendto(senderSock, (data_pkt_t*) &file_to_send[index + counter], sizeof(file_to_send[index + counter]), 0, (struct sockaddr*) &receiverSock_addr, receiverSock_addr_len) == -1)
		    {
    	   perror("file-sender:Error while sending file!");
    	   close(senderSock);
    	   exit(-1);
		    }
        chunks_info[index + counter].send = 1;
        counter++;
      }
    }

    if (recvfrom(senderSock, &ack, sizeof(ack_pkt_t), 0, (struct sockaddr*) &receiverSock_addr, &receiverSock_addr_len) == -1)
		{
    	if(errno == (EAGAIN | EWOULDBLOCK)){
        //Em caso de erro vamos ver as menssagens que ainda nao foram recebidas e vamos dizer q estas ainda nao foram enviadas
        int i = index;
        while(i < index +window_size){
          if(chunks_info[i].ack == 0){
            counter--;
            chunks_info[i].send = 0;

          }
        }
        continue;
    	}

      perror("file-sender:Error while receiving!");
	    close(senderSock);
	    exit(-1);
  	}

    //Vamos confirmar o ack que nos foi enviado
    /*if(ack.seq_num == 1){
      ack.seq_num = 65;
    }*/
    give_ack(ack, chunks_info, index, window_size);
    //Vamos ver se podemos mexer a janela
    move_window(&index, chunks_info, &counter);
  }
	puts("terminated with sucess");
  exit(0);
}
