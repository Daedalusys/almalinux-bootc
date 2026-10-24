PODMAN = sudo podman

IMAGE_NAME = almalinux-bootc
VERSION_MAJOR = 10
# This fork ships the kitten variant only: the Containerfile directory and the
# image tag both follow the variant name, matching the :10-kitten /
# :10-kitten-<arch> tags CI publishes (docs/REGISTRY.md).
VARIANT := $(VERSION_MAJOR)-kitten
IMAGE_TAG := $(VARIANT)
PLATFORM = linux/amd64
LABELS ?=

.ONESHELL:
.PHONY: all
all: rechunk

.PHONY: image
image:
	$(PODMAN) build \
		--platform=$(PLATFORM) \
		--security-opt=label=disable \
		--cap-add=all \
		--device /dev/fuse \
		--iidfile /tmp/image-id \
		$(LABELS) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) \
		-f $(VARIANT)/Containerfile \
		.

rechunk:
	$(PODMAN) run \
		--rm --privileged \
		--security-opt=label=disable \
		-v /var/lib/containers:/var/lib/containers:z \
		quay.io/centos-bootc/centos-bootc:stream10 \
		/usr/libexec/bootc-base-imagectl rechunk \
		localhost/$(IMAGE_NAME):$(IMAGE_TAG) localhost/rechunked-$(IMAGE_NAME):$(IMAGE_TAG) && \
	$(PODMAN) tag localhost/rechunked-$(IMAGE_NAME):$(IMAGE_TAG) localhost/$(IMAGE_NAME):$(IMAGE_TAG) && \
	$(PODMAN) rmi localhost/rechunked-$(IMAGE_NAME):$(IMAGE_TAG)
