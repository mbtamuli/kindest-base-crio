IMG ?= ghcr.io/mbtamuli/kindest-base-crio:main

.PHONY: run
run:
	docker pull --platform linux/amd64 ${IMG}
	$(eval $@_IMG := $(shell docker manifest inspect \$(IMG) | jq -r '.manifests | map(select(.platform.architecture == "amd64")) | .[0].digest'))
	kind create cluster -v7 --wait 1m --retain --config=kind-config-crio.yaml --image=$($@_TMP)
