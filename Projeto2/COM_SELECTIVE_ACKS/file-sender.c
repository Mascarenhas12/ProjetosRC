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
#include <netdb.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>

#include "packet-format.h"
#include "window.h"

#define MAX_CHUNK_SIZE 1000
#define MAX_SEQ_NUM 64


// Does not account for circular logic!
static int read_file_chunk(char* buffer, int cursor, FILE* fp)
{
	int bytes_read;

	memset(buffer, 0, sizeof(char) * MAX_CHUNK_SIZE);

	if (fseek(fp, cursor * MAX_CHUNK_SIZE, SEEK_SET) == -1)
		return -1;

	if ((bytes_read = fread(buffer, 1, MAX_CHUNK_SIZE, fp)) < MAX_CHUNK_SIZE && ferror(fp))
		return -1;

	return bytes_read;
}


static int build_data_packet(data_pkt_t* data_pkt, int seq_num, FILE* fp)
{
	data_pkt->seq_num = seq_num;
	return read_file_chunk(data_pkt->data, seq_num - 1, fp);
}


static void exit_failure(char* msg, int sockFd, data_pkt_t* data_pkt, ack_pkt_t* ack_pkt, window_t* window)
{
	perror(msg);
	close(sockFd);
	free_w(window);
	free(data_pkt);
	free(ack_pkt);
	exit(-1);
}


int main(int argc, char const *argv[])
{
	struct hostent* host;
	int port;

	FILE* fp;
	int bytes_read;

	int senderSock;
	struct sockaddr_in receiverSock_addr;
	socklen_t receiverSock_addr_len;
	struct timeval timeout;
	int timeout_counter;
	
	long num_packets;
	data_pkt_t* data_pkt;
	ack_pkt_t* ack_pkt;
	int selective_acks;

	window_t* window;
	int w_size;
	int w_base;
	int w_advance;


	/* ======================================================================================== */
	/* Argument verification                                                                    */
	/* ======================================================================================== */


	if (argc != 5)
	{
		perror("file-sender:Wrong number of arguments! <file> <host> <port> <window_size>");
		exit(-1);
	}

	if ((host = gethostbyname(argv[2])) == NULL)
	{
		perror("file-sender:Invalid host name!");
		exit(-1);
	}

	if ((port = atoi(argv[3])) > 65535)
	{
		perror("file-sender:Invalid port number!");
		exit(-1);
	}

	if ((w_size = atoi(argv[4])) > MAX_WINDOW_SIZE)
	{
		perror("file-sender:Invalid window size!");
		exit(-1);
	}

	/* ======================================================================================== */
	/* Verify and open file                                                                     */
	/* ======================================================================================== */


	if ((fp = fopen(argv[1], "rb")) == NULL)
	{
		perror("file-sender:Error opening file!");
		exit(-1);
	}
	fseek(fp, 0, SEEK_END);

	num_packets = ftell(fp) / MAX_CHUNK_SIZE + 1;


	/* ======================================================================================== */
	/* Create UDP socket and set timeout option                                                 */
	/* ======================================================================================== */


	if ((senderSock = socket(AF_INET, SOCK_DGRAM, 0)) == -1)
	{
		perror("file-sender:Error creating socket!");
		exit(-1);
	}

	timeout.tv_sec = 1;
	timeout.tv_usec = 0;

	if (setsockopt(senderSock, SOL_SOCKET, SO_RCVTIMEO, (char*) &timeout, sizeof(timeout)) == -1 ||
			setsockopt(senderSock, SOL_SOCKET, SO_REUSEADDR, &(int){1}, sizeof(int)) == -1)
	{
		perror("file-sender:Error setting socket options!");
		close(senderSock);
		exit(-1);
	}
	receiverSock_addr_len = sizeof(struct sockaddr_in);

	memset(&receiverSock_addr, 0, sizeof(receiverSock_addr));
	receiverSock_addr.sin_family = AF_INET;
	receiverSock_addr.sin_port = htons(port);
	receiverSock_addr.sin_addr = *((struct in_addr *) host->h_addr);


	/* ======================================================================================== */
	/* Send and receive loop                                                                    */
	/* ======================================================================================== */

	window = create_w(atoi(argv[4]), num_packets, 0);
	w_base = get_base_w(window);
	w_advance = w_size; // Util explicitar ultimo avanço na janela para deduzir quais os packets novos na janela a enviar

	data_pkt = (data_pkt_t*) malloc(sizeof(data_pkt_t));
	ack_pkt = (ack_pkt_t*) malloc(sizeof(ack_pkt_t));
	selective_acks = 0;

	timeout_counter = 0;

	while (!empty_w(window))
	{
		if (timeout_counter == 0)
		{
			// Primeira vez corre janela toda (w_advance = w_size). Vezes seguintes comeca na posicao da janela com packets novos a enviar
			for (int i = (w_base + w_size) - w_advance; i < w_base + w_size; i++)
			{
				// Usa fseek, não ha buffers
				if ((bytes_read = build_data_packet(data_pkt, i, fp)) == -1)
					exit_failure("file-sender:Error while reading from file!", senderSock, data_pkt, ack_pkt, window);

				if (sendto(senderSock, (data_pkt_t*) data_pkt, bytes_read + sizeof(int), 0, 
				(struct sockaddr*) &receiverSock_addr, receiverSock_addr_len) == -1)
				{
					exit_failure("file-sender:Error while sending data!", senderSock, data_pkt, ack_pkt, window);
				}
			}
		}
		else // Em caso de timeout, correr window toda e reenviar baseado no selective acks
		{
			for (int i = w_base; i < w_base + w_size; i++)
			{
				// Sel_acks nao conta 1o pacote da janela, que é preciso enviar de certeza
				// Presumindo que janelas estao sincronizadas... Caso contrario pode haver merda se chegar aqui
				if (i != w_base && selective_acks % 2)
				{
					selective_acks /= 2;
					continue;
				}
				else if (i != w_base)
				{
					selective_acks /= 2;
				}

				// Usa fseek, não ha buffers
				if ((bytes_read = build_data_packet(data_pkt, i, fp)) == -1)
					exit_failure("file-sender:Error while reading from file!", senderSock, data_pkt, ack_pkt, window);

				if (sendto(senderSock, (data_pkt_t*) data_pkt, bytes_read + sizeof(int), 0, 
				(struct sockaddr*) &receiverSock_addr, receiverSock_addr_len) == -1)
				{
					exit_failure("file-sender:Error while sending data!", senderSock, data_pkt, ack_pkt, window);
				}
			}
		}

		if (recvfrom(senderSock, (ack_pkt_t*) ack_pkt, sizeof(ack_pkt_t), 0,
		(struct sockaddr*) &receiverSock_addr, &receiverSock_addr_len) == -1)
		{
			if (errno == (EAGAIN | EWOULDBLOCK))
			{
				if (++timeout_counter == 3)
					exit_failure("Shut down after 3 consecutive timeouts!", senderSock, data_pkt, ack_pkt, window);
				continue;
			}
			else
				exit_failure("file-sender:Error while receiving ACK!", senderSock, data_pkt, ack_pkt, window);
		}
		selective_acks = ack_pkt->selective_acks; // Atualizar sel_acks
		timeout_counter = 0; // Se chegou aqui recebeu um packet, logo faz-se reset ao counter 

		if (contains_w(window, ack_pkt->seq_num - 1))
		{
			w_advance = ack_pkt->seq_num - w_base;
			w_base = advance_w(window, w_advance);
		}
	}

	close(senderSock);
	free_w(window);
	free(data_pkt);
	free(ack_pkt);

	puts("Terminated with success.");

	exit(0);
}
