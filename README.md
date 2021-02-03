<div align="center">
  <h3>NA joi-news for AWS interview-pairing content</h3>
  <h1>techops-recsys-infra-hiring/joi-news-aws-na</h1>
  <h5>NA Recruitment</h5>
</div>
<br />


This project contains three services:

* `quotes` which serves a random quote from `quotes/resources/quotes.json`
* `newsfeed` which aggregates several RSS feeds together
* `front-end` which calls the two previous services and displays the results.

The services are provided as docker images. This README documents the steps to build the images and provision the infrastructure for the services.  

They interviewer will have pre-deployed this application and the underlying infrastructure in advance of the pairing session.  

As described in the email you received with the link to this content, review the deployments files to familiarize yourself with these services. During the interview, the interviewer will discuss potential improvements and ask you to make and apply the changes. Please come prepared to discuss and apply at least one improvement based on your own review of this content.  

# Initial Setup

## Development and operations tools setup

There are 2 options for getting the right tools on developer's laptop:
 * **quick** leverage Docker+Dojo. Requires only to install docker and dojo on your laptop.
 * **manual** requires to install all tools manually

 The rest of this file describes the quick way, please refer to [MANUAL_SETUP.md](MANUAL_SETUP.md) for the other option.

### Docker+Dojo setup

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

## Localize the Code

In addition to the link to download this code amples, you will have been provided with a CODE_PREFIX. This is usually you last name. Please confirm in the email.  

From the command line, define the necessary environment variable and run the localization script as follow:  

```sh
$ export CODE_PREFIX=****
$ make localize
```

Your code sample should now match that used by the Interview to prepare for the pairing session.  

## Infrastructure Components  

THere are three elements to the infrastructure configuration.  

1. backend-support

This is the S3 bucket and DynamoDB table to support locking for the remote terraform state.  

2. base

The base resources to support deploying the apps:

- ECR repositories for the Docker images
- IAM configuration for the compute
- VPC

3. news app infra

The princple pieces of infrastructure for the news app.  

During the pairing exercise you will not be interacting with the backend-support components though of course you may discuss alternative approaches if you believe there are superior alternatives. 

### Setup aws credentials

The interviewer will send you an email with AWS credentials, which you should export in your shell.

```sh
export CODE_PREFIX=****              # same as above
export AWS_SECRET_ACCESS_KEY=****
export AWS_ACCESS_KEY_ID=****
export AWS_DEFAULT_REGION=us-east-1
```

## Infrastructure changes

Once you have set the above environment variables, you will be able to make and deploy code changes.  

### Deploy changes

Depending on where you make a change, one or more of the following commands can be used to apply.  

1. make base.infra  

To apply changes to the base infrastructure.   

2. make news.infra  

To apply changes to the News application infrastructure and deployment.  

One of the outputs from this process is the URL for the news application. The interviewer will provide you the current url and you will also see this in the output as you make changes.  

frontend_url = http://34.244.219.156:8080  

3. make deploy_site

To re-deploy the application static content if needed.  
