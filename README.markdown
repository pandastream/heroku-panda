# Heroku - Panda

This is a plugin for the Heroku command line, adding commands to grant S3 bucket access to Panda.


## Installation

    $ heroku plugins:install http://github.com/newbamboo/heroku-panda.git

## Config

The plugin assumes you already have panda gem installed.

It will fetch Panda variables(PANDASTREAM_*) from the Heroku app config vars.

## Usage

Setup S3 Bucket

    $ heroku panda:setup_bucket $S3_BUCKET ($S3_KEY $S3_SECRET)

If you don't provide $S3_KEY and $S3_SECRET variables, we will assume that you set the variables at Heroku Config Vars.

