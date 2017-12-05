# superluminar.io website

This repo hosts the source code and deploy pipeline for https://superluminar.io.

It uses [Hugo](gohugo.io) as the blogging/website engine.
Styling is done with [basscss.com](basscss.com).

# Prerequisites

```
make install
```

# Run it

```
./hugo serve -D
```

# Build it
```
make build
```
It will be created in the directory `public`. This gets synced to S3. Done.

# How it works

Content is in [content](content). Every file is written in Markdown. CSS and template is in [theme/superluminar](theme/superluminar).

# Cloudformation setup

A [AWS Lambda function](https://github.com/arabold/aws-to-slack) to forward SNS messages from the build pipeline to our Slack:
```
SLACK_HOOK_URL=... SLACK_CHANNEL=... make deploy-slack-hook
```

The `superluminar-website` organization holds the S3 bucket and CloudFront setup.

```
aws cloudformation create-stack --stack-name superluminar-website-prod --profile superluminar-website --region us-east-1 --template-body file://superluminar-website-prod.yaml --parameters ParameterKey=GithubOauthToken,ParameterValue=XXXXXXXXXXXXOC --capabilities CAPABILITY_IAM
```

The `superluminar-root` organization holds the Route53 DNS records.
```
aws cloudformation create-stack --stack-name superluminar-website-route53-prod --region us-east-1 --template-body file://superluminar-website-route53-prod.yaml --parameters ParameterKey=WebsiteCdn,ParameterValue=d116j9abb012r4.cloudfront.net ParameterKey=CloudFrontDistributionRedirect,ParameterValue=dxqw1tlirzvbi.cloudfront.net --capabilities CAPABILITY_IAM
```
