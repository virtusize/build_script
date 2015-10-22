define HELP_MESSAGE
Usage: make [COMMAND]

Commands:
	build        Build a Docker image.
	tag          Tag the created image in local repository.
	push         Push the Docker image to Docker Hub, will not push develop or feature-* tags.
	force-push   Push the Docker image to Docker Hub.
	help         Display this help message.

Docker tags for git branches:
	master       Git describe (i.e. 5.3.1) and <master> and <latest> for latest
	develop      Branch name: <develop>
	release      Version number of branch with 'release-' prefix (i.e. release-5.3.1) and <release> for latest
	hotfix       Version number of branch with 'hotfix-' prefix (i.e. hotfix-5.3.1) and <hotfix> for latest
	feature      Branch name: <feature-some-name> - will not be pushed to Docker hub, but you can push manually with force-push.
endef

export HELP_MESSAGE

ORG_NAME := virtusize
APP_NAME := $(shell basename $(CURDIR))
DOCKER_IMAGE_NAME := $(ORG_NAME)/$(APP_NAME)
IGNORE_TAGS := feature-%

GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_TAG := $(shell git describe --tags --always)

ifeq ($(GIT_BRANCH),master)
TAGS := $(GIT_TAG) master latest
endif

ifeq ($(GIT_BRANCH),develop)
TAGS := develop
endif

ifneq (,$(findstring release,$(GIT_BRANCH)))
TAGS := $(subst /,-,$(GIT_BRANCH)) release
endif

ifneq (,$(findstring hotfix,$(GIT_BRANCH)))
TAGS := $(subst /,-,$(GIT_BRANCH)) hotfix
endif

ifneq (,$(findstring feature,$(GIT_BRANCH)))
TAGS := $(subst /,-,$(GIT_BRANCH))
endif

LIMITED_TAGS := $(filter-out $(IGNORE_TAGS),$(TAGS))

define log_info 
echo "\033[0;36m$1\033[0m"
endef

.PHONY : build test tag push help


build:

	@echo "Organization: $(ORG_NAME)"
	@echo "Application: $(APP_NAME)"
	@echo "Branch: $(GIT_BRANCH)"
	@echo "Tag: $(GIT_TAG)"
	git status --porcelain

	@$(call log_info,Building image: $(DOCKER_IMAGE_NAME):$(word 1,$(TAGS)))
	@docker build -t $(DOCKER_IMAGE_NAME):$(word 1,$(TAGS)) .


test:

	@$(call log_info,Running tests for image: [ $(DOCKER_IMAGE_NAME):$(word 1,$(TAGS)) ])
	@docker run -t --net=host $(DOCKER_IMAGE_NAME):$(word 1,$(TAGS)) make test


tag:

	@$(call log_info,Tagging $(DOCKER_IMAGE_NAME):$(word 1,$(TAGS)) with: [ $(foreach t,$(wordlist 2,$(words $(TAGS)),$(TAGS)),$(t) )])
	$(foreach t,$(wordlist 2,$(words $(TAGS)),$(TAGS)), docker tag -f $(DOCKER_IMAGE_NAME):$(word 1,$(TAGS)) $(DOCKER_IMAGE_NAME):$(t);)


push: tag
	@$(call log_info,Pushing image: [ $(foreach t,$(LIMITED_TAGS),$(DOCKER_IMAGE_NAME):$(t) )])
	$(foreach t,$(LIMITED_TAGS),docker push $(DOCKER_IMAGE_NAME):$(t);)


force-push: tag
	@$(call log_info,Pushing image: [ $(foreach t,$(TAGS),$(DOCKER_IMAGE_NAME):$(t) )])
	$(foreach t,$(TAGS),docker push $(DOCKER_IMAGE_NAME):$(t);)


help:

	@echo "$$HELP_MESSAGE"
