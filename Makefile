HUGO_VERSION := 0.40.2
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

develop: hugo ## Start a development server
	./hugo serve -D

public: hugo ## Build the website
	./hugo

install: hugo ## Install dependencies (hugo)

build: public ## Build the website

build-preview: guard-BASE_URL ## Build the preview website
	./hugo --baseURL $(BASE_URL)

deploy: public guard-WEBSITE_BUCKET guard-CLOUDFRONT_DISTRIBUTION_ID ## Deploys the website to the S3 bucket
	aws s3 sync public/ s3://$(WEBSITE_BUCKET)/ --delete
	aws configure set preview.cloudfront true
	aws cloudfront create-invalidation --distribution-id=$(CLOUDFRONT_DISTRIBUTION_ID) --paths /

deploy-preview: public guard-PREVIEW_BUCKET guard-BUCKET_PATH ## Deploys a preview of the website to the S3 bucket
	aws s3 sync public/ s3://$(PREVIEW_BUCKET)/$(BUCKET_PATH) --delete

deploy-pipeline: ## Deploys the AWS CodePipeline that deploys the website
	aws cloudformation deploy \
		--stack-name superluminar-website-prod \
		--region us-east-1 \
		--template-file superluminar-website-prod.yaml \
		--capabilities CAPABILITY_IAM

deploy-preview-pipeline: ## Deploys the AWS CodeBuildProject that deploys the website preview
	aws cloudformation deploy \
		--stack-name deploy-preview-codebuild \
		--region us-east-1 \
		--template-file superluminar-website-preview.yaml \
		--capabilities CAPABILITY_IAM

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
