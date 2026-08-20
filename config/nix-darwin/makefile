# Variables
HOSTNAME := $(shell scutil --get LocalHostName)
USERNAME := $(shell whoami)
USERID := $(shell id -u)
ARCH := $(shell uname -m)
SYSTEM := $(if $(filter arm64,$(ARCH)),aarch64-darwin,$(if $(filter x86_64,$(ARCH)),x86_64-darwin,$(error Unsupported architecture: $(ARCH))))

# Colors
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
NC := \033[0m # No Color

.PHONY: all build switch check clean update help

# Default target
all: check build switch

config:
	@echo "${GREEN}Current configuration:${NC}"
	@echo "Hostname: ${YELLOW}$(HOSTNAME)${NC}"
	@echo "Username: ${YELLOW}$(USERNAME)${NC}"
	@echo "System: ${YELLOW}$(SYSTEM)${NC}"
	@echo "Architecture: ${YELLOW}$(ARCH)${NC}"
	@echo ""

# Show help
help:
	@echo "Available targets:"
	@echo "  ${GREEN}all${NC}     - Check, build and switch configuration (default)"
	@echo "  ${GREEN}build${NC}   - Build the configuration"
	@echo "  ${GREEN}switch${NC}  - Build and switch to the configuration"
	@echo "  ${GREEN}check${NC}   - Check the configuration"
	@echo "  ${GREEN}clean${NC}   - Clean build artifacts"
	@echo "  ${GREEN}update${NC}  - Update flake inputs"
	@echo ""
	@make config

# Check configuration
check: config
	@echo "${GREEN}Checking for required tools...${NC}"
	@./scripts/check_and_install.sh
	@echo "${GREEN}Checking configuration...${NC}"
	@nix flake check

# Build configuration
build: config
	@echo "${GREEN}Building configuration...${NC}"
	@env HOST=$(HOSTNAME) USER=$(USERNAME) UID=$(USERID) nix build .#darwinConfigurations.$(HOSTNAME).system --impure

# Switch to configuration
switch: build
	@echo "${GREEN}Switching to new configuration...${NC}"
	@sudo env HOST=$(HOSTNAME) USER=$(USERNAME) UID=$(USERID) ./result/sw/bin/darwin-rebuild switch --flake .#$(HOSTNAME) --impure
	@echo "${GREEN}Cleaning up...${NC}"
	@rm -rf ./result

# Clean build artifacts
clean:
	@echo "${GREEN}Cleaning build artifacts...${NC}"
	@rm -rf ./result
	@nix store gc

# Update flake inputs
update:
	@echo "${GREEN}Updating flake inputs...${NC}"
	@nix flake update

# Format nix files
fmt:
	@echo "${GREEN}Formatting nix files...${NC}"
	@nix fmt
