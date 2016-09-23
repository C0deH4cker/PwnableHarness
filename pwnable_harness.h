//
//  pwnable_harness.h
//  PwnableHarness
//
//  Created by C0deH4cker on 11/15/13.
//  Copyright (c) 2013 C0deH4cker. All rights reserved.
//

#ifndef PWNABLE_HARNESS_H
#define PWNABLE_HARNESS_H

#include <stdbool.h>

/*! Signature of the function used to handle connections
 * @param sock Opened file descriptor for the socket connection
 */
typedef void conn_handler(int sock);

/*! Options given to the server to change how it runs. */
typedef struct server_options {
	const char* user;            /*!< Username of the account used to run child processes */
	bool chrooted;               /*!< True if the server should run within a chroot */
	unsigned short port;         /*!< Port bound for receiving incoming connections */
	unsigned time_limit_seconds; /*!< Max number of seconds to run child processes for before they're killed */
} server_options;


/*! Starts a fork/exec-ing socket server after parsing command line arguments to perform configuration changes.
 * @param argc Argument count
 * @param argv Argument vector
 * @param opts Default values for configurable server options which can be overridden with command line arguments
 * @param handler Function pointer invoked to handle each connection
 * @return Zero on success, or nonzero on error
 */
int server_main(int argc, char** argv, server_options opts, conn_handler* handler);

/*! Starts a fork/exec-ing socket server with the specified creation options with the given connection handler.
 * @param user Name of Unix account that child processes are created under
 * @param chrooted True if the server will enter a chroot and chdir to the home directory at launch
 * @param port Port the challenge runs on
 * @param timeout Number of seconds the connection is allowed to run before being killed, or 0 for no timeout
 * @param handler Function pointer invoked to handle each connection
 * @return Zero on success, or nonzero on error
 * @note To allow command line options to override the default options, use server_main instead.
 */
int serve(const char* user, bool chrooted, unsigned short port, unsigned timeout, conn_handler* handler);


#endif /* EXP_HARNESS_H */
