//
//  pwnable_harness.c
//  PwnableHarness
//
//  Created by C0deH4cker on 11/15/13.
//  Copyright (c) 2013 C0deH4cker. All rights reserved.
//

#include "pwnable_harness.h"
#include <stdlib.h>
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

/* For reading argv[0] without access to argv. */
extern char *program_invocation_name;

/*! Actually output to standard error after it has been moved. */
#define PERROR(msg) fprintf(stderr_fp, "%s: %s\n", (msg), strerror(errno))

/* Original file descriptors */
static int real_stdin, real_stdout, real_stderr;
static FILE* stdin_fp, *stdout_fp, *stderr_fp;

/*! Name of the environment variable used to mark a connection handler process. */
static const char* kEnvMarker = "PWNABLE_CONNECTION";


/*! Changes directory to the user's home directory, chroots there, and then
 * changes to the user's home directory relative to the chroot.
 * @note This expects the user's home directory to be the root for the chroot,
 *   and it also assumes that once in the chroot it can access the user's home
 *   directory relative to the chroot. So if the user's home directory is
 *   /home/example, then there should be a /home/example/home/example.
 *   In that case, the program will be chrooted within /home/example, and
 *   it will run from /home/example/home/example (which appears to just be
 *   /home/example from within the chroot). Yeah, I know, confusing. Just
 *   use Docker, it's easier and less confusing ^_^.
 */
static bool enter_chroot(struct passwd* pw) {
	/* Change directory FIRST! */
	if(chdir(pw->pw_dir) != 0) {
		fprintf(stderr, "Error: Couldn't change to user's home directory.\n");
		perror(pw->pw_dir);
		return false;
	}
	
	/* NOW, we can call chroot. */
	if(chroot(pw->pw_dir) != 0) {
		fprintf(stderr, "Error: Couldn't chroot to user's home directory.\n");
		perror("chroot");
		return false;
	}
	
	/* Once again chdir to the user's home directory, this time to the one in the chroot. */
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
	/* Make sure these are NULL */
	stdin_fp = stdout_fp = stderr_fp = NULL;
	
	/* Duplicate standard file descriptors */
	if((real_stdin  = dup(STDIN_FILENO))  == -1 ||
	   (real_stdout = dup(STDOUT_FILENO)) == -1 ||
	   (real_stderr = dup(STDERR_FILENO)) == -1) {
		goto fail;
	}
	
	/* Open file pointers to newly duplicated standard file descriptors */
	stdin_fp = fdopen(real_stdin, "rb");
	if(!stdin_fp) {
		goto fail;
	}
	
	stdout_fp = fdopen(real_stdout, "wb");
	if(!stdout_fp) {
		goto fail;
	}
	
	stderr_fp = fdopen(real_stderr, "wb");
	if(!stderr_fp) {
		goto fail;
	}
	
	/* Close original standard file descriptors */
	close(STDIN_FILENO);
	close(STDOUT_FILENO);
	close(STDERR_FILENO);
	
	return true;
	
fail:
	/*
	 * fclose() will close() the fd associated with the given
	 * file pointer, so no need to call close() after fclose().
	 */
	if(stdin_fp) {
		fclose(stdin_fp);
	}
	else if(real_stdin != -1) {
		close(real_stdin);
	}
	
	if(stdout_fp) {
		fclose(stdout_fp);
	}
	else if(real_stdout != -1) {
		close(real_stdout);
	}
	
	if(stderr_fp) {
		fclose(stderr_fp);
	}
	else if(real_stderr != -1) {
		close(real_stderr);
	}
	
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
	
	return true;
}

static void handle_term(int signum) {
	fprintf(stderr_fp, "Got SIGTERM, exiting...");
	exit(signum);
}


int serve(const char* user, bool chrooted, unsigned short port, unsigned timeout, conn_handler* handler) {
	/* 
	 * For exec-ing servers, check for a marker environment variable.
	 * If this is set, that means we have just been exec-ed to handle
	 * a client connection. Therefore, instead of starting up the socket
	 * server, just call the connection handler.
	 */
	char* marker = getenv(kEnvMarker);
	if(marker != NULL) {
		/* Make sure these standard output streams are not buffered */
		setvbuf(stdout, NULL, _IONBF, 0);
		setvbuf(stderr, NULL, _IONBF, 0);
		
		/* Invoke actual challenge function */
		handler(atoi(marker));
		return EXIT_SUCCESS;
	}
	
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
	
	if(chrooted) {
		/* Chroot into the user's home directory */
		if(!enter_chroot(pw)) {
			return EXIT_FAILURE;
		}
	}
	
	/* Ignore dead children so they don't turn into zombies */
	if(signal(SIGCHLD, SIG_IGN) == SIG_ERR) {
		perror("signal");
		return EXIT_FAILURE;
	}
	
	/* Handle SIGTERM so that when running in Docker as PID 1 we properly exit */
	if(signal(SIGTERM, &handle_term) == SIG_ERR) {
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
	
	/* Allow incoming connections from anywhere */
	memset(&serv_addr, 0, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = INADDR_ANY;
	serv_addr.sin_port = htons(port);
	
	/* Bind to port */
	if(bind(sock, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) != 0) {
		perror("bind");
		return EXIT_FAILURE;
	}
	
	/* Listen for connections, with a maximum backlog of 128 connections to accept */
	if(listen(sock, 128) != 0) {
		perror("listen");
		return EXIT_FAILURE;
	}
	
	/* Move standard file descriptors away from their normal positions */
	if(!move_stdio()) {
		fprintf(stderr_fp, "Error: Unable to move standard file descriptors.\n");
		return EXIT_FAILURE;
	}
	
	/* Display useful information about the server process */
	fprintf(stderr_fp, "Server process id: %u\n", getpid());
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
			
			/* Set connection marker environment variable to the connection socket */
			char conn_str[11];
			snprintf(conn_str, sizeof(conn_str), "%u", conn);
			if(setenv(kEnvMarker, conn_str, 0) != 0) {
				PERROR("setenv");
				_exit(EXIT_FAILURE);
			}
			
			/* Close real standard file handles */
			fclose(stdin_fp);
			fclose(stdout_fp);
			fclose(stderr_fp);
			
			/* Now exec ourselves to run the actual challenge code */
			execl("/proc/self/exe", program_invocation_name, NULL);
			
			/* Should hopefully never make it this far */
			abort();
		}
	} while(noclose || close(conn) != -1);
	
	/* If this is reached, the connection couldn't be closed successfully. */
	PERROR("close");
	return EXIT_FAILURE;
}

int server_main(int argc, char** argv, server_options opts, conn_handler* handler) {
	bool listen = false;
	int i;
	for(i = 1; i < argc; i++) {
		if(strcmp(argv[i], "--listen") == 0 || strcmp(argv[i], "-l") == 0) {
			listen = true;
		}
		else if(strcmp(argv[i], "--no-chroot") == 0) {
			opts.chrooted = false;
		}
		else if(strcmp(argv[i], "--user") == 0 || strcmp(argv[i], "-u") == 0) {
			opts.user = argv[++i];
		}
		else if(strcmp(argv[i], "--port") == 0 || strcmp(argv[i], "-p") == 0) {
			opts.port = atoi(argv[++i]);
		}
		else if(strcmp(argv[i], "--alarm") == 0 || strcmp(argv[i], "-a") == 0) {
			opts.time_limit_seconds = atoi(argv[++i]);
		}
		else {
			printf(
				"Error: Unkown argument '%s'\n"
				"Usage: %s [options]\n"
				"  Options:\n"
				"    -l, --listen                   "
					"Run the server and listen for incoming connections\n"
				"    -a, --alarm <seconds=%3d>      "
					"Time limit for child processes to run, or 0 to disable\n"
				"    --no-chroot                    "
					"Prevent the server from entering a chroot and changing directory\n"
				"    -p, --port <port=%05hu>        "
					"Set the port the server listens on for incoming connections\n"
				"    -u, --user <user=%s>%*s"
					"Name of the user that child processes should run as\n",
				argv[i],
				argv[0],
				opts.time_limit_seconds,
				opts.port,
				opts.user, 13 - (int)strlen(opts.user), ""
			);
			return EXIT_FAILURE;
		}
	}
	
	/* If not run with --listen, just call the connection handler function directly */
	if(!listen) {
		setenv(kEnvMarker, "0", 0);
	}
	
	return serve(opts.user, opts.chrooted, opts.port, opts.time_limit_seconds, handler);
}

