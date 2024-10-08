#include <stdio.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdbool.h>
#include <sys/mman.h>

struct stupid_list {
	struct stupid_list* next;
};


static bool flush_line(void) {
	int c;
	do {
		c = getchar();
	} while(c != EOF && c != '\n');
	
	return c != EOF;
}



static void busy_loop(void) {
	volatile uint64_t x = 0;
	
	/* Busy loop! */
	while(1) {
		x++;
	}
}


static const char* get_bytes_unit(unsigned unit) {
	switch(unit) {
		case 0: return "B";
		case 1: return "KiB";
		case 2: return "MiB";
		case 3: return "GiB";
		case 4: return "TiB";
		case 5: return "PiB";
		case 6: return "EiB";
	}
	
	return "?iB";
}

static const char* format_byte_count(size_t n) {
	unsigned unit = 0;
	unsigned d = 0;
	while(n > 1024) {
		d = n % 1024;
		n /= 1024;
		unit++;
	}
	
	/* Max length is "1023.99MiB\0" aka 11 bytes */
	static char fmtbuf[11];
	snprintf(fmtbuf, sizeof(fmtbuf), "%zu.%02u%s", n, d * 100 / 1024, get_bytes_unit(unit));
	return fmtbuf;
}


static void memory_leak(void) {
	printf(
		"How many pages to map each iteration?\n"
		"> "
	);
	
	unsigned page_count;
	while(scanf("%u", &page_count) != 1) {
		if(!flush_line()) {
			printf("\n");
			exit(EXIT_FAILURE);
		}
		printf(
			"Enter a non-negative integer.\n"
			"> "
		);
	}
	
	int page_size = getpagesize();
	if(page_size <= 0) {
		perror("getpagesize");
		exit(EXIT_FAILURE);
	}
	
	size_t alloc_size = page_count * (size_t)page_size;
	struct stupid_list list = {0};
	struct stupid_list** pnext = &list.next;
	
	/* Memory leak! Grow an infinite linked list of dirty pages */
	unsigned wasted_pages = 0;
	while(1) {
		void* map = mmap(NULL, alloc_size, PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
		if(map == MAP_FAILED) {
			perror("mmap");
			
			/* Hold onto the memory that has already been allocated, but don't waste CPU */
			sleep(1);
		}
		
		/* Create the link, also marking the first page as dirty */
		*pnext = map;
		pnext = &(*pnext)->next;
		
		/* Touch all pages after the first to ensure they're dirty */
		unsigned i;
		for(i = 1; i < page_count; i++) {
			char* p = (char*)map + i * page_size;
			*p = 'D'; //dirty
		}
		
		wasted_pages += page_count;
		printf("Wasted %u pages (%s)!\n", wasted_pages, format_byte_count(wasted_pages * (size_t)page_size));
	}
}


static void fork_bomb(void) {
	/* Fork bomb! */
	while(1) {
		fork();
	}
}


int main(int argc, char** argv) {
	printf(
		"What sort of punishment should be inflicted?\n"
		"1) Infinite busy loop\n"
		"2) Memory leak\n"
		"3) Fork bomb\n"
		"\n"
		"> "
	);
	
	int choice;
	while(scanf("%d", &choice) != 1 || choice < 1 || choice > 3) {
		if(!flush_line()) {
			printf("\n");
			exit(EXIT_FAILURE);
		}
		printf(
			"Invalid choice\n"
			"> "
		);
	}
	
	switch(choice) {
		case 1:
			busy_loop();
			break;
		
		case 2:
			memory_leak();
			break;
		
		case 3:
			fork_bomb();
			break;
	}
	
	return 0;
}
