# superluminar.io website

This repo hosts the source code and deploy pipeline for https://superluminar.io.

It uses [Hugo](gohugo.io).

# Prerequisites

```
make hugo
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

Content is in [content]. Every file is written in Markdown. CSS and template is in [theme/superluminar]. It's using [basscss.com].
