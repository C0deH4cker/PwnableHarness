#include <stdio.h>
#include <string.h>

int main(void) {
	char lsb_release[100];
	
	const char* path = "/etc/lsb_release";
	FILE* fp = fopen(path, "r");
	if (!fp) {
		perror(path);
		return -1;
	}
	
	if (!fgets(lsb_release, sizeof(lsb_release), fp)) {
		perror(path);
		return -1;
	}
	
	fclose(fp);
	
	// Remove end of line character if present
	char* s = lsb_release;
	strsep(&s, "\n\r");
	
	printf("Hello! This program is running on: %s\n", lsb_release);
	return 0;
}
