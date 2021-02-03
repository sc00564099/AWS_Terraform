BUILD_DIR=build
APPS=front-end quotes newsfeed
LIBS=common-utils
STATIC_BASE=front-end/public
STATIC_PATHS=css
STATIC_ARCHIVE=$(BUILD_DIR)/static.tgz
INSTALL_TARGETS=$(addsuffix .install, $(LIBS))
APP_JARS=$(addprefix $(BUILD_DIR)/, $(addsuffix .jar, $(APPS)))
DOCKER_TARGETS=$(addsuffix .docker, $(APPS))
DOCKER_PUSH_TARGETS=$(addsuffix .push, $(APPS))
_DOCKER_PUSH_TARGETS=$(addprefix _, $(DOCKER_PUSH_TARGETS))
ECR_URL_FILE=infra/ecr-url.txt
SSH_KEY=infra/id_rsa
SKIP_BUILD=${SKIP_APP_BUILD}

_all: $(BUILD_DIR) $(APP_JARS) $(STATIC_ARCHIVE)

_libs: $(addprefix _, $(INSTALL_TARGETS))

static: $(STATIC_ARCHIVE)

_%.install:
	cd $* && lein install

_test: $(addprefix _, $(addsuffix .test, $(LIBS) $(APPS)))

test:
	dojo "make _test"

_%.test:
	cd $* && lein midje

_apps:
	make _libs clean _all

apps:
	dojo "make _apps"

clean:
	rm -rf $(BUILD_DIR) $(addsuffix /target, $(APPS)) $(addsuffix /target, $(LIBS))

$(APP_JARS): | $(BUILD_DIR)
	cd $(notdir $(@:.jar=)) && lein uberjar && cp target/uberjar/*-standalone.jar ../$@

$(STATIC_ARCHIVE): | $(BUILD_DIR)
	tar -c -C $(STATIC_BASE) -z -f $(STATIC_ARCHIVE) $(STATIC_PATHS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

%.docker:
	$(eval IMAGE_NAME = $(subst -,_,$*))
	cp $(BUILD_DIR)/$*.jar docker/$*
	cd docker/$* && docker build -t $(IMAGE_NAME) .

_%.push:
	$(eval IMAGE_NAME = $(subst -,_,$*))
	$(eval REPO_URL := $(shell cat ${ECR_URL_FILE}))
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(REPO_URL)$(IMAGE_NAME)
	docker tag $(IMAGE_NAME) $(REPO_URL)$(IMAGE_NAME)
	docker push $(REPO_URL)$(IMAGE_NAME)

%.push:
	$(eval IMAGE_NAME = $(subst -,_,$*))
	$(eval REPO_URL := $(shell cat ${ECR_URL_FILE}))
	aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(REPO_URL)$(IMAGE_NAME)
	docker tag $(IMAGE_NAME) $(REPO_URL)$(IMAGE_NAME)
	docker push $(REPO_URL)$(IMAGE_NAME)

docker: $(DOCKER_TARGETS)

_push: $(_DOCKER_PUSH_TARGETS)
push: $(DOCKER_PUSH_TARGETS)

$(SSH_KEY):
	ssh-keygen -q -N "" -f $(SSH_KEY)
	chmod 0600 $(SSH_KEY)

ssh_key: $(SSH_KEY)

_%.infra: ssh_key
	cd infra/$* && rm -rf .terraform && terraform init && terraform apply --auto-approve

%.infra:
	dojo "make _$*.infra"

_%.deinfra: ssh_key
	rm -f interview_id.txt && cd infra/$* && terraform init && terraform destroy -auto-approve

%.deinfra:
	dojo "make _$*.deinfra"

_deploy_site:
	cd build &&\
	mkdir -p static &&\
	cd static &&\
	tar xf ../static.tgz &&\
	aws s3 sync . s3://news$$(cat ../../interview_id.txt)-terraform-infra-static-pages/

deploy_site:
	dojo "make _deploy_site"

# Interview time:
_interview_id.txt:
	date | md5sum | cut -c -14 > interview_id.txt
	find ./infra -type f -exec sed -i "s/news4321/news$$(cat interview_id.txt)/g" {} \;

interview_id.txt:
	# Run in docker to get consistent sed behaviour
	dojo "make _interview_id.txt"

randomize: interview_id.txt

_randomize: _interview_id.txt

localize:
	dojo "bash localize.sh"
	
deploy_interview: 
	$(MAKE) backend-support.infra
	$(MAKE) base.infra
	$(MAKE) docker # builds all images
	$(MAKE) push
	$(MAKE) news.infra
	$(MAKE) deploy_site

# deploy_interview: randomize
# ifeq ($(SKIP_BUILD), true)
# 	echo "Request to skip app build received."
# ifeq ($(and $(wildcard build/front-end.jar),$(wildcard build/quotes.jar),$(wildcard build/newsfeed.jar),$(wildcard build/static.tgz)),)
# 	echo "One or More required build files is missing. Cannot Skip App Build."
# 	$(MAKE) apps
# else
# 	echo "All required files present in build directory. Skipping App Build."
# endif
# else
# 	echo "Running App build"
# 	$(MAKE) apps
# endif
# 	$(MAKE) backend-support.infra
# 	$(MAKE) base.infra
# 	$(MAKE) docker # builds all images
# 	$(MAKE) push
# 	$(MAKE) news.infra
# 	$(MAKE) deploy_site

destroy_interview:
	$(MAKE) news.deinfra
	$(MAKE) base.deinfra
	$(MAKE) backend-support.deinfra
