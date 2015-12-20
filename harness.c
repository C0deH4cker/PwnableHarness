//
//  harness.c
//  PwnableHarness
//
//  Created by C0deH4cker on 11/15/13.
//  Copyright (c) 2013 C0deH4cker. All rights reserved.
//

#include "harness.h"
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <time.h>
#include <signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <grp.h>
#include <pwd.h>

/*! Actually output to standard error after it has been moved. */
#define PERROR(msg) fprintf(stderr_fp, "%s: %s\n", (msg), strerror(errno))

/* Original file descriptors. */
static int real_stdin, real_stdout, real_stderr;
static FILE* stdin_fp, *stdout_fp, *stderr_fp;


/*! Changes directory to the user's home directory, chroots there, and then
 changes to the user's home directory relative to the chroot.
 */
static bool enter_chroot(struct passwd* pw) {
	/* Change directory FIRST! */
	if(chdir(pw->pw_dir) != 0) {
		fprintf(stderr, "Error: Couldn't change to user's home directory.\n");
		perror(pw->pw_dir);
		return false;
	}
	
	/* NOW, we can call chroot */
	if(chroot(pw->pw_dir) != 0) {
		fprintf(stderr, "Error: Couldn't chroot to user's home directory.\n");
		perror("chroot");
		return false;
	}
	
	/* Once again chdir to the user's home directory, this time to the one in the chroot */
	if(chdir(pw->pw_dir) != 0) {
		fprintf(stderr, "Error: Couldn't change to the chrooted home directory.\n");
		perror(pw->pw_dir);
		return false;
	}
	
	return true;
}

/*! Reduce privileges from root to the specified user. */
static bool drop_privileges(struct passwd* pw) {
	/* Clear supplementary groups list */
	if(initgroups(pw->pw_name, pw->pw_gid)) {
		fprintf(stderr_fp, "Error: Couldn't clear groups list.\n");
		return false;
	}
	
	/* Set group id */
	if(setgid(pw->pw_gid)) {
		fprintf(stderr_fp, "Error: Couldn't set group id.\n");
		return false;
	}
	
	/* Set user id */
	if(setuid(pw->pw_uid)) {
		fprintf(stderr_fp, "Error: Couldn't set user id.\n");
		return false;
	}
	
	/* If unable to restore root, it was successful */
	if(setuid(0) != -1) {
		/* Root privileges restored? This is very bad. Commit suicide */
		fprintf(stderr_fp, "Error: root privileges restored: %d\n", getuid());
		return false;
	}
	
	/* All privileges dropped */
	return true;
}

/* Moves standard IO file descriptors away from the default values. */
static bool move_stdio(void) {
	if((real_stdin  = dup(STDIN_FILENO))  == -1 ||
	   (real_stdout = dup(STDOUT_FILENO)) == -1 ||
	   (real_stderr = dup(STDERR_FILENO)) == -1) {
		goto close_fds;
	}
	
	if(!(stdin_fp = fdopen(real_stdin, "rb"))) {
		goto close_fds;
	}
	
	if(!(stdout_fp = fdopen(real_stdout, "wb"))) {
		fclose(stdin_fp);
		real_stdin = -1;
		goto close_fds;
	}
	
	if(!(stderr_fp = fdopen(real_stderr, "wb"))) {
		fclose(stdin_fp);
		fclose(stdout_fp);
		real_stdin = real_stdout = -1;
		goto close_fds;
	}
	
	close(STDIN_FILENO);
	close(STDOUT_FILENO);
	close(STDERR_FILENO);
	
	return true;
	
close_fds:
	if(real_stdin  != -1) close(real_stdin);
	if(real_stdout != -1) close(real_stdout);
	if(real_stderr != -1) close(real_stderr);
	
	return false;
}

/* Redirects standard IO file descriptors to the socket. */
static bool redirect_output(int sock) {
	if(dup2(sock, STDIN_FILENO) == -1) {
		PERROR("dup2(stdin)");
		return false;
	}
	
	if(dup2(sock, STDOUT_FILENO) == -1) {
		close(STDIN_FILENO);
		PERROR("dup2(stdout)");
		return false;
	}
	
	if(dup2(sock, STDERR_FILENO) == -1) {
		close(STDIN_FILENO);
		close(STDOUT_FILENO);
		PERROR("dup2(stderr)");
		return false;
	}
	
	/* Make sure these standard output streams are line buffered */
	setvbuf(stdout, NULL, _IOLBF, 0);
	setvbuf(stderr, NULL, _IOLBF, 0);
	
	return true;
}


int serve(const char* user, unsigned short port, unsigned timeout, conn_handler* handler) {
	/* Elevate to root privileges before doing anything else */
	if(setuid(0) != 0) {
		fprintf(stderr, "Error: Unable to become root!\n");
		perror("setuid(0)");
		return EXIT_FAILURE;
	}
	
	/* Double check that we are root */
	if(getuid() != 0) {
		fprintf(stderr, "Error: Still not root!\n");
		return EXIT_FAILURE;
	}
	
	/* Look up user struct */
	struct passwd* pw = getpwnam(user);
	if(!pw) {
		fprintf(stderr, "Error: Couldn't find user '%s'.\n", user);
		return EXIT_FAILURE;
	}
	
	/* Chroot into the user's home directory */
	if(!enter_chroot(pw)) {
		return EXIT_FAILURE;
	}
	
	/* Ignore dead children so they don't turn into zombies */
	if(signal(SIGCHLD, SIG_IGN) == SIG_ERR) {
		perror("signal");
		return EXIT_FAILURE;
	}
	
	/* Create socket */
	int sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if(sock == -1) {
		perror("socket");
		return EXIT_FAILURE;
	}
	
	/* Allow socket to reuse the serv_addr */
	int reuse = 1;
	if(setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuse, sizeof(reuse)) != 0) {
		perror("setsockopt");
		return EXIT_FAILURE;
	}
	
	struct sockaddr_in serv_addr, cli_addr;
	socklen_t cli_len = sizeof(cli_addr);
	
	memset(&serv_addr, 0, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = INADDR_ANY;
	serv_addr.sin_port = htons(port);
	
	/* Bind to port */
	if(bind(sock, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) != 0) {
		perror("bind");
		return EXIT_FAILURE;
	}
	
	/* Listen for connections */
	if(listen(sock, 5) != 0) {
		perror("listen");
		return EXIT_FAILURE;
	}
	
	/* Move standard file descriptors away from their normal positions */
	if(!move_stdio()) {
		fprintf(stderr_fp, "Error: Unable to move standard file descriptors.\n");
		return EXIT_FAILURE;
	}
	
	fprintf(stderr_fp, "Now accepting connections on port %hu (0x%04hx)\n\n", port, port);
	
	/* Accept connections */
	int conn;
	bool noclose;
	do {
		noclose = false;
		
		/* Wait for a client connection */
		conn = accept(sock, (struct sockaddr*)&cli_addr, &cli_len);
		if(conn == -1) {
			PERROR("accept");
			noclose = true;
			continue;
		}
		
		/* Handle the client connection in a subprocess */
		pid_t pid = fork();
		if(pid < 0) {
			PERROR("fork");
			return EXIT_FAILURE;
		}
		else if(pid == 0) {
			/* Close the controlling socket descriptor so connections cannot be hijacked */
			close(sock);
			
			/* Prevent long-running connections from hogging up the system */
			if(timeout > 0) {
				alarm(timeout);
			}
			
			/* Create timestamp string */
			time_t curtime = time(NULL);
			char* timestamp = ctime(&curtime);
			char* p = strchr(timestamp, '\n');
			if(p != NULL) {
				*p = '\0';
			}
			
			/* Log timestamp and source IP for received connections */
			uint32_t ip = ntohl(cli_addr.sin_addr.s_addr);
			fprintf(stderr_fp, "[%s] Received connection from %u.%u.%u.%u.\n",
			        timestamp, ip>>24, (ip>>16)&255, (ip>>8)&255, ip&255);
			
			/* Redirect stdio to the socket */
			if(!redirect_output(conn)) {
				fprintf(stderr_fp, "Failed to redirect IO to socket.\n");
				_exit(EXIT_FAILURE);
			}
			
			/* Only the child process should drop privileges */
			if(!drop_privileges(pw)) {
				fprintf(stderr_fp, "Unable to drop privileges... Committing suicide.\n");
				_exit(EXIT_FAILURE);
			}
			
			/* Close duplicated IO file descriptors */
			fclose(stdin_fp);
			fclose(stdout_fp);
			fclose(stderr_fp);
			
			/* Now jump over to the real code for the challenge */
			handler(conn);
			
			/* Close the remaining file descriptors */
			close(conn);
			close(STDIN_FILENO);
			close(STDOUT_FILENO);
			close(STDERR_FILENO);
			
			/* Exit the child process */
			_exit(EXIT_SUCCESS);
		}
	} while(noclose || close(conn) != -1);
	
	/* If this is reached, the connection couldn't be closed successfully. */
	PERROR("close");
	return EXIT_FAILURE;
}

