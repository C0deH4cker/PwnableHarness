#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>

int main() {
	int urandfd = open("/dev/urandom", O_RDONLY);
	if(urandfd < 0) {
		perror("/dev/urandom");
		return EXIT_FAILURE;
	}
	
	unsigned char c = 0;
	if(read(urandfd, &c, 1) != 1) {
		perror("read");
		return EXIT_FAILURE;
	}
	
	close(urandfd);
	
	unsigned target = c % 100 + 1;
	printf("Enter this number (%u): ", target);
	
	unsigned guess = 0;
	if(scanf("%u", &guess) != 1) {
		printf("Bad input.\n");
		return EXIT_FAILURE;
	}
	
	if(guess != target) {
		printf("Incorrect guess! The correct answer was %u.\n", target);
	}
	else {
		printf("Great job!\n");
	}
	
	return EXIT_SUCCESS;
}
