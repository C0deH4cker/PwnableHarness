//
//  stack0.c
//  PwnableHarness
//
//  Created by C0deH4cker on 11/15/13.
//  Copyright (c) 2013 C0deH4cker. All rights reserved.
//

#include <stdio.h>
#include <stdbool.h>
#include <stddef.h>
#include <string.h>
#include <sys/socket.h>
#include "harness.h"


/* Filename of the first flag */
static const char* flagfile = "flag1.txt";

/* Simple helper function to send a string of text to a socket. */
static ssize_t sendText(int sock, const char* text) {
	return send(sock, text, strlen(text), 0);
}

/* Send the user the contents of the first flag file. */
static void giveFlag(int sock) {
	char flag[64];
	FILE* fp = fopen(flagfile, "r");
	if(!fp) {
		perror(flagfile);
		return;
	}
	
	fgets(flag, sizeof(flag), fp);
	fclose(fp);
	
	sendText(sock, "Here is your first flag:\n");
	sendText(sock, flag);
}

/* Called when an incoming client connection is received. */
static void handle_connection(int sock) {
	char txt[64];
	bool didPurchase = false;
	char input[50];
	
	snprintf(txt, sizeof(txt), "Debug info: Address of input buffer = %p\n", input);
	sendText(sock, txt);
	
	sendText(sock, "Enter the name you used to purchase this program: ");
	recv(sock, input, 1024, 0);
	
	if(didPurchase) {
		sendText(sock, "Thank you for purchasing Hackersoft Powersploit!\n");
		giveFlag(sock);
	}
	else {
		sendText(sock, "This program has not been purchased.\n");
	}
}

int main(void) {
	/* Run on port 32101 for 30 seconds as user "ctf_stack0" */
	return serve("ctf_stack0", 32101, 30, &handle_connection);
}
