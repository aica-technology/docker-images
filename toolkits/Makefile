SHELL := /bin/bash
.DEFAULT_GOAL := help

# ---------- Defaults (non-Jetson) ----------
PYTHON_VERSION ?= 3.12
UBUNTU_VERSION ?= 24.04
ROS_DISTRO     ?= jazzy
TRT_IMAGE      ?= nvcr.io/nvidia/tensorrt
TRT_TAG        ?= 24.12-py3

# ---------- Jetson-specific defaults ----------
JETSON_PYTHON_VERSION ?= 3.10
JETSON_UBUNTU_VERSION ?= 22.04
JETSON_TRT_IMAGE      ?= nvcr.io/nvidia/l4t-tensorrt
JETSON_TRT_TAG        ?= r8.6.2-devel

# ---------- Toggles ----------
PUSH      ?= 0
REBUILD   ?= 0
VERBOSE   ?= 0
MULTIARCH ?= 0
PLATFORM  ?=
EXTRA     ?=   # free-form extra args appended to the command

# ---------- Common flag composers ----------
# ---------- Common flag composers ----------
FLAGS_COMMON := $(strip \
  $(if $(filter 1,$(REBUILD)),--rebuild,) \
  $(if $(filter 1,$(VERBOSE)),-v,) \
  $(if $(filter 1,$(PUSH)),--push,) \
)

# only for non-Jetson (Jetson builds generally run on-device; avoid forcing platforms)
FLAGS_ARCH := $(strip \
  $(if $(filter 1,$(MULTIARCH)),--multiarch,$(if $(PLATFORM),--platform $(PLATFORM),)) \
)

define FLAGS_BASE
--tensorrt-image $(TRT_IMAGE) \
--tensorrt-image-tag $(TRT_TAG) \
--ubuntu-version $(UBUNTU_VERSION) \
--python-version $(PYTHON_VERSION) \
--ros-distro $(ROS_DISTRO)
endef

define FLAGS_JETSON_BASE
--tensorrt-image $(JETSON_TRT_IMAGE) \
--tensorrt-image-tag $(JETSON_TRT_TAG) \
--ubuntu-version $(JETSON_UBUNTU_VERSION) \
--python-version $(JETSON_PYTHON_VERSION) \
--ros-distro $(ROS_DISTRO)
endef

.PHONY: help
help:
	@echo "Targets:"
	@echo "  make ml-cpu              # ML toolkit (CPU)"
	@echo "  make ml-gpu              # ML toolkit (GPU)"
	@echo "  make ml-jetson           # ML toolkit (Jetson/L4T)"
	@echo "  make cuda                # CUDA toolkit (x86_64/arm64)"
	@echo "  make cuda-jetson         # CUDA toolkit (Jetson/L4T)"
	@echo ""
	@echo "Common overrides (examples):"
	@echo "  PUSH=1 REBUILD=1 VERBOSE=1 MULTIARCH=1 PLATFORM=amd64|arm64"
	@echo "  PYTHON_VERSION, UBUNTU_VERSION, ROS_DISTRO, TRT_IMAGE, TRT_TAG"
	@echo "  JETSON_PYTHON_VERSION, JETSON_UBUNTU_VERSION, JETSON_TRT_IMAGE, JETSON_TRT_TAG"
	@echo "  EXTRA='-- FOO=bar'   # appended to command as build args"

# ------------------ ML ------------------
.PHONY: ml-cpu
ml-cpu:
	./build.sh --ml-toolkit --target cpu \
	$(FLAGS_BASE) \
	$(FLAGS_COMMON) $(FLAGS_ARCH) \
	$(EXTRA)

.PHONY: ml-gpu
ml-gpu:
	./build.sh --ml-toolkit --target gpu \
	$(FLAGS_BASE) \
	$(FLAGS_COMMON) $(FLAGS_ARCH) \
	$(EXTRA)

.PHONY: ml-jetson
ml-jetson:
	./build.sh --ml-toolkit --target jetson \
	$(FLAGS_JETSON_BASE) \
	$(FLAGS_COMMON) \
	$(EXTRA)

# ------------------ CUDA ------------------
.PHONY: cuda
cuda:
	./build.sh --cuda-toolkit --target gpu \
	$(FLAGS_BASE) \
	$(FLAGS_COMMON) $(FLAGS_ARCH) \
	$(EXTRA)

.PHONY: cuda-jetson
cuda-jetson:
	./build.sh --cuda-toolkit --target jetson \
	$(FLAGS_JETSON_BASE) \
	$(FLAGS_COMMON) \
	$(EXTRA)
