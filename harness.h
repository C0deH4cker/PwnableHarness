//
//  harness.h
//  PwnableHarness
//
//  Created by C0deH4cker on 11/15/13.
//  Copyright (c) 2013 C0deH4cker. All rights reserved.
//

#ifndef EXP_HARNESS_H
#define EXP_HARNESS_H

/*! Signature of the function used to handle connections
 @param sock Opened socket descriptor for the session
 */
typedef void conn_handler(int sock);

/*! Starts a forking socket server with the specified creation options with the given connection handler
 @param user Name of Unix account that child processes are created under
 @param port Port the challenge runs on
 @param timeout Number of seconds the connection is allowed to run before being killed, or 0 for no timeout
 @param handler Function pointer invoked to handle each connection
 @return Zero on success, or nonzero on error
 */
int serve(const char* user, unsigned short port, unsigned timeout, conn_handler* handler);


#endif /* EXP_HARNESS_H */
