# Bazel rule to generate AWS Lambda packages

This repository contains bazel rules to create packages suitable for uploading to AWS Lambda.

## Setup
In your `WORKSPACE` file:
```
rules_version="7a4c548db7ceba7a997cc4ef3d21954700782ef5" # update this as needed

http_archive(
    name = "io_bazel_rules_aws_lambda",
    strip_prefix = "rules_aws_lambda-%s" % rules_version,
    type = "zip",
    url = "https://github.com/oyachai/rules_aws_lambda/archive/%s.zip" % rules_version,
)
```

## Usage
See the examples [here](examples/)