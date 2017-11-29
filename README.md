# superluminar.io website

This repo hosts the source code and deploy pipeline for https://superluminar.io.

It uses [Hugo](gohugo.io).

# Prerequisites

```
# MAC
brew install hugo

# LINUX
go get github.com/kardianos/govendor
govendor get github.com/gohugoio/hugo
go install github.com/gohugoio/hugo
```

# Run it

```
hugo serve -D
```

# How it works

Content is in [content]. Every file is written in Markdown.

To render the site run:
```
hugo
```

It will be created in the directory `public`. This gets synced to S3. Done.
