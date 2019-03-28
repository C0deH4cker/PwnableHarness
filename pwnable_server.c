//
//  pwnable_server.c
//  PwnableHarness
//
//  Created by C0deH4cker on 3/24/19.
//  Copyright (c) 2019 C0deH4cker. All rights reserved.
//

#include <stddef.h>
#include "pwnable_harness.h"

int main(int argc, char** argv) {
	/* These will likely all be overridden by the passed arguments */
	server_options opts = {
		.user = "nobody",
		.chrooted = false,
		.port = 65001,
		.time_limit_seconds = 0
	};
	
	return server_main(argc, argv, opts, NULL);
}