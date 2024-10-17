TARGET := base-image

UBUNTU_VERSION := 18.04

PUBLISH := base-image.c
PUBLISH_BUILD := $(TARGET)
PUBLISH_LIBC := my-libc.so
PUBLISH_LD := my-ld.so

DOCKER_IMAGE := pwnableharness-example-base-image
DOCKER_PORTS := 1804
DOCKER_WRITEABLE := true
