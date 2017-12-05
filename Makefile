HUGO_VERSION := 0.31.1
ifeq ($(shell uname),Darwin)
	OS := macOS
else
	OS := Linux
endif

.PHONY: clean
clean:
	rm -fr public tmp

.PHONY: clobber
clobber: clean
	rm -fr hugo

.PHONY: guard-%
guard-%:
	@ if [ "${${*}}" = "" ]; then \
	    echo "Environment variable $* not set"; \
	    exit 1; \
	fi

hugo:
	mkdir -p tmp
	curl -LsS https://github.com/gohugoio/hugo/releases/download/v$(HUGO_VERSION)/hugo_$(HUGO_VERSION)_$(OS)-64bit.tar.gz | tar xzf - hugo

public: hugo
	./hugo

install: hugo

build: public

deploy: public guard-WEBSITE_BUCKET
	aws s3 sync public/ s3://$(WEBSITE_BUCKET)/ --delete

tmp/superluminar-website-slack-hook-prod.yaml:
	mkdir -p tmp
	curl -LsS https://s3.amazonaws.com/aws-to-slack/cloudformation.yaml -o $@

deploy-slack-hook: tmp/superluminar-website-slack-hook-prod.yaml guard-SLACK_HOOK_URL guard-SLACK_CHANNEL
	aws cloudformation deploy \
		--profile superluminar-website \
		--stack-name superluminar-website-slack-hook-prod \
		--region us-east-1 \
		--template-file $< \
		--parameter-overrides "HookUrl=$(SLACK_HOOK_URL)" "Channel=$(SLACK_CHANNEL)" \
		--capabilities CAPABILITY_IAM

