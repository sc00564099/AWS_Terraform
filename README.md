<div align="center">
  <h3>NA joi-news for AWS interview-pairing content</h3>
  <h1>techops-recsys-infra-hiring/joi-news-aws-na</h1>
  <h5>NA Recruitment experiment</h5>
</div>
<br />


This project contains three services:

* `quotes` which serves a random quote from `quotes/resources/quotes.json`
* `newsfeed` which aggregates several RSS feeds together
* `front-end` which calls the two previous services and displays the results.

The services are provided as docker images. This README documents the steps to build the images and provision the infrastructure for the services.

# Development and operations tools setup

There are 2 options for getting the right tools on developer's laptop:
 * **quick** leverage Docker+Dojo. Requires only to install docker and dojo on your laptop.
 * **manual** requires to install all tools manually

 The rest of this file describes the quick way, please refer to [MANUAL_SETUP.md](MANUAL_SETUP.md) for the other option.

## Docker+Dojo setup

We can leverage docker to define required build and operations dependencies by referencing docker images.

[Dojo](https://github.com/kudulab/dojo) is a similar tool to [batect](https://github.com/charleskorn/batect/). It is just a wrapper around docker commands to bring up a well-defined development environment in containers.

This is the recommended approach as it enforces consistency between CI setup and the tools used by developers.

Assuming you already have a working docker, you can install dojo

**On OSX** with:

```sh
brew install kudulab/homebrew-dojo-osx/dojo
```

**On Linux** with:

```sh
DOJO_VERSION=0.8.0
wget -O dojo https://github.com/kudulab/dojo/releases/download/${DOJO_VERSION}/dojo_linux_amd64
sudo mv dojo /usr/local/bin
sudo chmod +x /usr/local/bin/dojo
```

This project is also using `make`, so ensure that you have that on your PATH too.

# Infrastructure setup

This is a multi-step guide to setup some base infrastructure, and then, on top of it, the test environment for the newsfeed application.

## Base infrastructure setup

With an assumption that we have a new, empty AWS account, we need to provision some base infrastructure just one time.
These steps will provision:
 * terraform backend in S3 bucket and locking with DynamoDB
 * a minimal VPC with 2 subnets
 * ECR repositories for docker images

### Setup aws credentials
The interviewer will send you an email with AWS credentials, which you should export in your shell.

```sh
export CODE_PREFIX=****
export AWS_SECRET_ACCESS_KEY=****
export AWS_ACCESS_KEY_ID=****
```

Now run:

```sh
./randomize.sh
make backend-support.infra
make base.infra
```

## Build the application artifacts

If you haven't built the jars and static resources yet, you should do so now:

```sh
make apps
```

## Build docker images

Artifacts from previous stage will be packaged into docker images, then pushed to ECR.

Each application has its own image. Individual image can be built with:

```sh
make <app-name>.docker
# for example:
make front-end.docker
```

But you can build all images at once with

```sh
make docker
```

## Push docker images

Before applications can be deployed on AWS, the docker images have to be pushed:

```sh
make push
```

## Provision services

Then, we can provision the backend and front-end services:

```sh
make news.infra
```

Terraform will print the output with URL of the front_end server, e.g.

```
Outputs:

frontend_url = http://34.244.219.156:8080
```

## Delete services

To delete the deployment provisioned by terraform, run following commands:

```sh
make news.deinfra
```
