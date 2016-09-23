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
#include <unistd.h>
#include "pwnable_harness.h"


/* Filename of the first flag */
static const char* flagfile = "flag1.txt";

/* Send the user the contents of the first flag file. */
static void giveFlag(void) {
	char flag[64];
	FILE* fp = fopen(flagfile, "r");
	if(!fp) {
		perror(flagfile);
		return;
	}
	
	fgets(flag, sizeof(flag), fp);
	fclose(fp);
	
	printf("Here is your first flag: %s\n", flag);
}

/* Called when an incoming client connection is received. */
static void handle_connection(int sock) {
	bool didPurchase = false;
	char input[50];
	
	printf("Debug info: Address of input buffer = %p\n", input);
	
	printf("Enter the name you used to purchase this program: ");
	read(STDIN_FILENO, input, 1024);
	
	if(didPurchase) {
		printf("Thank you for purchasing Hackersoft Powersploit!\n");
		giveFlag();
	}
	else {
		printf("This program has not been purchased.\n");
	}
}

int main(int argc, char** argv) {
	/* Defaults: Run on port 32101 for 30 seconds as user "ctf_stack0" inside a chroot */
	server_options opts = {
		.user = "ctf_stack0",
		.chrooted = true,
		.port = 32101,
		.time_limit_seconds = 30
	};
	
	return server_main(argc, argv, opts, &handle_connection);
}
