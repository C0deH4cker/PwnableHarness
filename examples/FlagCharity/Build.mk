# Name of the challenge executable to build
TARGET := charity

# Build a Docker image named "charity" that exposes the challenge on port 19891
DOCKER_IMAGE := charity
DOCKER_PORTS := 19891

# On `make publish`, copy the executable and charity.c to `PwnableHarness/publish`
PUBLISH_BUILD := $(TARGET)
PUBLISH := charity.c
