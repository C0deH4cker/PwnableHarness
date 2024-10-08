#include <stdio.h>
#include <string.h>
#include <gnu/libc-version.h>

int main(void) {
	char os_version[100];
	
	printf("glibc version: %s\n", gnu_get_libc_version());
	
	const char* path = "/etc/issue";
	FILE* fp = fopen(path, "r");
	if (!fp) {
		perror(path);
		return -1;
	}
	
	if (!fgets(os_version, sizeof(os_version), fp)) {
		perror(path);
		return -1;
	}
	
	fclose(fp);
	
	// Remove end of line character if present
	char* s = os_version;
	strsep(&s, "\n\r");
	
	printf("/etc/issue: %s\n", os_version);
	return 0;
}
