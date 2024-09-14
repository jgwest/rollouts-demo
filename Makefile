COLOR?=
IMAGE_NAMESPACE?=
ERROR_RATE?=
IMAGE_TAG?=latest

# Tool to build the container image. It can be either docker or podman
DOCKER ?= docker

ifneq (${COLOR},)
IMAGE_TAG=${COLOR}
endif
ifneq (${LATENCY},)
IMAGE_TAG=slow-${COLOR}
endif
ifneq (${ERROR_RATE},)
IMAGE_TAG=bad-${COLOR}
endif

ifdef IMAGE_NAMESPACE
IMAGE_PREFIX=${IMAGE_NAMESPACE}/
endif

.PHONY: all
all: build

.PHONY: build
build:
	CGO_ENABLED=0 go build

.PHONY: image
image:
	$(DOCKER) build --build-arg COLOR=${COLOR} --build-arg ERROR_RATE=${ERROR_RATE} --build-arg LATENCY=${LATENCY} -t $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG} .
	@if [ "$(DOCKER_PUSH)" = "true" ] ; then $(DOCKER) push $(IMAGE_PREFIX)rollouts-demo:$(IMAGE_TAG) ; fi

# Build multiple platform image
.PHONY: image-all-manifest
image-all-manifest:
	$(DOCKER) build  --platform linux/amd64 --build-arg COLOR=${COLOR} --build-arg ERROR_RATE=${ERROR_RATE} --build-arg LATENCY=${LATENCY} -t $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}-amd64 .
	$(DOCKER) build  --platform linux/arm64 --build-arg COLOR=${COLOR} --build-arg ERROR_RATE=${ERROR_RATE} --build-arg LATENCY=${LATENCY} -t $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}-arm64 .
	$(DOCKER) build  --platform linux/ppc64le --build-arg COLOR=${COLOR} --build-arg ERROR_RATE=${ERROR_RATE} --build-arg LATENCY=${LATENCY} -t $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}-ppc64le .
	$(DOCKER) build  --platform linux/s390x --build-arg COLOR=${COLOR} --build-arg ERROR_RATE=${ERROR_RATE} --build-arg LATENCY=${LATENCY} -t $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}-s390x .

	$(DOCKER) manifest rm $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG} || true
	$(DOCKER) manifest create $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}
	$(DOCKER) manifest add $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG} $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}-amd64
	$(DOCKER) manifest add $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG} $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}-arm64
	$(DOCKER) manifest add $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG} $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}-ppc64le
	$(DOCKER) manifest add $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG} $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG}-s390x
	@if [ "$(DOCKER_PUSH)" = "true" ] ; then $(DOCKER) manifest push $(IMAGE_PREFIX)rollouts-demo:${IMAGE_TAG} ; fi

.PHONY: load-tester-image
load-tester-image:
	cd load-tester
	$(DOCKER) build -t $(IMAGE_PREFIX)load-tester:latest load-tester
	@if [ "$(DOCKER_PUSH)" = "true" ] ; then $(DOCKER) push $(IMAGE_PREFIX)load-tester:latest ; fi

.PHONY: run
run:
	go run main.go

.PHONY: lint
lint:
	golangci-lint run --fix

.PHONY: release
release:
	./release.sh DOCKER_PUSH=${DOCKER_PUSH} IMAGE_NAMESPACE=${IMAGE_NAMESPACE}

.PHONY: clean
clean:
	rm -f rollouts-demo
