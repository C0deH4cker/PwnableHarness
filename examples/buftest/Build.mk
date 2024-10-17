TARGET := buftest

# NO_UNBUFFERED_STDIO := true

# Enable everything else just for fun
NX := 1
ASLR := 1
RELRO := 1
CANARY := 1
STRIP := 1
DEBUG := 1

DOCKER_IMAGE := buftest
DOCKER_PORTS := 12345
