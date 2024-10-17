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
#include <stdlib.h>
#include <string.h>
#include <unistd.h>


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
static void handle_connection(void) {
	bool didPurchase = false;
	char input[50];
	
	printf("Debug info: Address of input buffer = %p\n", input);
	
	printf("Enter the name you used to purchase this program: ");
	ssize_t bytes_read = read(STDIN_FILENO, input, 256);
	if(bytes_read < 0) {
		perror("read");
		exit(EXIT_FAILURE);
	}
	else if(bytes_read == 0) {
		printf("Error reading input!\n");
		exit(EXIT_FAILURE);
	}
	
	if(didPurchase) {
		printf("Thank you for purchasing Hackersoft Powersploit!\n");
		giveFlag();
	}
	else {
		printf("This program has not been purchased.\n");
	}
}

int main(void) {
	handle_connection();
	return 0;
}
