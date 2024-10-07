//
//  stdio_unbuffer.c
//  PwnableHarness
//
//  Created by C0deH4cker on 3/24/19.
//  Copyright (c) 2019 C0deH4cker. All rights reserved.
//

#include <stdio.h>

__attribute__((constructor))
static void pwnable_unbuffer_init(void) {
	/* Make sure these standard output streams are not buffered */
	setvbuf(stdout, NULL, _IONBF, 0);
	setvbuf(stderr, NULL, _IONBF, 0);
}
