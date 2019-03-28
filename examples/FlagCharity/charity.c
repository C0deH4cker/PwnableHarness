#include <stdio.h>
#include <stdlib.h>

int main(void) {
	printf("Welcome to the Flag Charity. Do you want a shell? [Y/n]\n");
	
	char line[10];
	if(!fgets(line, sizeof(line), stdin) || line[0] == 'n' || line[0] == 'N') {
		printf("Hmm, guess you don't want a free flag...\n");
	}
	else {
		printf("Thought so. Here's your free shell!\n");
		system("/bin/sh");
	}
	
	return 0;
}
