# superluminar.io website-preview

This repo hosts the source code and deploy pipeline for https://superluminar.io.

It uses [Hugo](gohugo.io) as the blogging/website engine.
Styling is done with [basscss.com](basscss.com).

# Prerequisites

```
make install
```

# Edit and develop

```
> make develop

                   | EN
+------------------+----+
  Pages            | 29
  Paginator pages  |  0
  Non-page files   |  0
  Static files     | 16
  Processed images |  0
  Aliases          |  4
  Sitemaps         |  1
  Cleaned          |  0

Total in 32 ms
Watching for changes in /Users/jan/Code/superluminar-website/{content,layouts,static,themes}
Watching for config changes in /Users/jan/Code/superluminar-website/config.toml
Serving pages from memory
Running in Fast Render Mode. For full rebuilds on change: hugo server --disableFastRender
Web Server is available at http://localhost:1313/ (bind address 127.0.0.1)
Press Ctrl+C to stop
```

This will start a local server that renders the web page. Usually it is available at [http://localhost:1313](http://localhost:1313/). 

# Build it
```
make build
```
It will be created in the directory `public`. This gets synced to S3. Done.

# How it works

Content is in [content](content). Every file is written in Markdown. CSS and template is in [theme/superluminar](theme/superluminar).

# Cloudformation setup

The `superluminar-website` organization holds the S3 bucket and CloudFront setup.

```
aws cloudformation create-stack --stack-name superluminar-website-prod --profile superluminar-website --region us-east-1 --template-body file://superluminar-website-prod.yaml --parameters ParameterKey=GithubOauthToken,ParameterValue=XXXX ParameterKey=SlackHookUrl,ParameterValue=XXX --capabilities CAPABILITY_IAM
```

The `superluminar-root` organization holds the Route53 DNS records.
```
aws cloudformation create-stack --stack-name superluminar-website-route53-prod --region us-east-1 --template-body file://superluminar-website-route53-prod.yaml --parameters ParameterKey=WebsiteCdn,ParameterValue=d116j9abb012r4.cloudfront.net ParameterKey=CloudFrontDistributionRedirect,ParameterValue=dxqw1tlirzvbi.cloudfront.net --capabilities CAPABILITY_IAM
```

For just updating the pipeline stack run below:
```
make deploy-pipeline
```
