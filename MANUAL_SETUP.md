# DevOps Assessment

This project contains three services:

* `quotes` which serves a random quote from `quotes/resources/quotes.json`
* `newsfeed` which aggregates several RSS feeds together
* `front-end` which calls the two previous services and displays the results.

The services are provided as docker images. This README documents the steps to build the images and provision the infrastructure for the services.

# Development and operations tools setup

There are 2 options for getting the right tools on developer's laptop:
 * **quick** leverage Docker+Dojo. Requires only to install docker and dojo on your laptop.
 * **manual** requires to install all tools manually

 The rest of this file describes the manual way, please refer to [README.md](README.md) for the other option.

## Manual setup

You need all the tools below installed locally:

### Prerequisites to build the Java applications

 * make
 * Java
 * [Leiningen](http://leiningen.org/) (can be installed using `brew install leiningen`)

### Prerequisites for running infrastructure code

 * make
 * local docker daemon
 * terraform 0.12.6
 * ssh-keygen
 * AWS cli

# Infrastructure setup

This is a multi-step guide to setup some base infrastructure, and then, on top of it, the test environment for the newsfeed application.

## Base infrastructure setup

With an assumption that we have a new, empty AWS account, we need to provision some base infrastructure just one time.
These steps will provision:
 * terraform backend in S3 bucket and locking with DynamoDB
 * a minimal VPC with 2 subnets
 * ECR repositories for docker images

### Setup aws session
Look for the aws_session file in the code base and run:
```sh
source aws_session
```
Now run:
```sh
make _backend-support.infra
make _base.infra
```

## Build the application artifacts

If you haven't built the jars and static resources yet, you should do so now:
```sh
make _apps
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
make _push
```

## Provision services

Then, we can provision the backend and front-end services:
```sh
make _news.infra
```

Terraform will print the output with URL of the front_end server, e.g.
```
Outputs:

frontend_url = http://34.244.219.156:8080
```

## Delete services

To delete the deployment provisioned by terraform, run following commands:
```sh
make _news.deinfra
```
