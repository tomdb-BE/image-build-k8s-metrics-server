SEVERITIES = HIGH,CRITICAL

ifeq ($(ARCH),)
ARCH=$(shell go env GOARCH)
endif

BUILD_META ?= -build-multiarch-$(shell date +%Y%m%d)
ORG ?= rancher
# the metrics server has been moved to https://github.com/kubernetes-sigs/metrics-server
# but still refers internally to github.com/kubernetes-incubator/metrics-server packages
PKG ?= github.com/kubernetes-incubator/metrics-server
SRC ?= github.com/kubernetes-sigs/metrics-server
TAG ?= v0.3.7$(BUILD_META)
UBI_IMAGE ?= centos:7
GOLANG_VERSION ?= v1.16.6b7-multiarch

ifeq (,$(filter %$(BUILD_META),$(TAG)))
$(error TAG needs to end with build metadata: $(BUILD_META))
endif

.PHONY: image-build
image-build:
	docker build \
		--build-arg PKG=$(PKG) \
		--build-arg SRC=$(SRC) \
		--build-arg TAG=$(TAG:$(BUILD_META)=) \
                --build-arg GO_IMAGE=$(ORG)/hardened-build-base:$(GOLANG_VERSION) \
                --build-arg UBI_IMAGE=$(UBI_IMAGE) \
		--tag $(ORG)/hardened-k8s-metrics-server:$(TAG) \
		--tag $(ORG)/hardened-k8s-metrics-server:$(TAG)-$(ARCH) \
	.

.PHONY: image-push
image-push:
	docker push $(ORG)/hardened-k8s-metrics-server:$(TAG)-$(ARCH)

.PHONY: image-manifest
image-manifest:
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest create --amend \
		$(ORG)/hardened-k8s-metrics-server:$(TAG) \
		$(ORG)/hardened-k8s-metrics-server:$(TAG)-$(ARCH)
	DOCKER_CLI_EXPERIMENTAL=enabled docker manifest push \
		$(ORG)/hardened-k8s-metrics-server:$(TAG)

.PHONY: image-scan
image-scan:
	trivy --severity $(SEVERITIES) --no-progress --ignore-unfixed $(ORG)/hardened-k8s-metrics-server:$(TAG)
