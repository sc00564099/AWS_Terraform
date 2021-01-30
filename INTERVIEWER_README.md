*Dear candidate, please ignore this document and read the README.md instead*

# TL;DR

**As an interviewer on the day of pairing**:

1. Obtain a checkout/zip of this codebase and set to match candidates version.

```
Working from the resulting unzipped folder:

# match the code to the candidates
$ export CODE_PREFIX=<candidate's lastname>
$ bash randomize.sh
```

2. Make sure you have all tools installed:

```
Confirm you have a local [Docker(https://www.docker.com/products/docker-desktop) installation. 
Confirm a current version (1 or 2) of the aws cli is in your local path.  
Confirm `make` is in your path.   
Install [Dojo](https://github.com/kudulab/dojo). This provides a wrapper around docker commands to help provide a consistent development environment for containers and the candidate will likely be using the same.  
```

3. Access Okta Chiclet `AWS - NA Recruitment` and go to AWS console.  

4. Activate/Rotate you personal credentials

5. Deploying the infrastructure and news application (it takes between 15-25 minutes) by running:

```bash
# deploy the infrastructure
$ aws-vault exec tw.first.last --no-session -- make backend-support.infra
$ aws-vault exec tw.first.last --no-session -- make base.infra
$ make apps
$ make docker
$ aws-vault exec recruit.nic.cheneweth --no-session -- make push
$ aws-vault exec recruit.nic.cheneweth --no-session -- make news.infra



    make deploy_interview
    ```
   To save approx 10-15 mins you can skip building app jars during `make deploy_interview`. Set `export SKIP_APP_BUILD=true`
   before running. You would need to have built app jars atleast once for this to work. Check `build/` directory for app jars.



5. When it's time to pair with candidate, **you are responsible to give them AWS access**. There are 3 ways to do so:
 - If candidate is OK with using interviewer's laptop, just continue working from your laptop after running `eval $(./recops.sh login)`.
 - If candidate wants to use their laptop:
     - Run `./recops.sh candidate_prep`, this will produce a message with **Some instructions & AWS credentials that you can send to the candidate via email**.

[Optional] If for some reason you have to share the code on your machine with the candidate:
  - Run `./recops.sh prepare_candidate_zip`, this will produce a uniqe s3 link with the codebase which you can share with the candidate.

6. In the beginning of the interview - [deploy the entire solution in one go](#deployment-in-one-go) with: `make deploy_interview`.

# Prerequisites

## Adopting this in your region

### Okta & AWS

If you are adopting the new infrastructure code challenge for your region then you first need to add your regional
Okta and AWS information in the code base. You can do it as follows:

* Open up the `recops.sh` script
* Update `get_regional_okta_aws_info` function with your regions' Okta App ID & AWS Account ID
* It should then look something like this:

```bash
  AWS_OKTA_APP_IDS=(
    ["UK"]="0oa1hok6wfq5HpBgj0h8"
    ["DE"]="0oa1ih2bgpegSfjAt0h8"
    ["your_country_code_in_caps"]="<okta_app_id>"
  )

  AWS_ACCOUNT_IDS=(
    ["UK"]="339270093312"
    ["DE"]="841586536262"
    ["your_country_code_in_caps"]="<aws_account_id>"
  )

  read -r -n 1 -p $'Select your TW region:
    1 -> UK
    2 -> DE
    3 -> <your_country_code_in_caps>
```
Hint:
* Okta app ID can be found by simply hovering over the App icon in your Okta Dashboard (it's in the link)
* AWS account ID can be found once you click the App icon and it will take you to your AWS account.

**Note:** If you do not have the above information or access to the AWS account in your region, please read the [Infra. recruitment AWS regional guide](https://docs.google.com/document/d/1Fcanevf1FQsU70lm8jy-MAsScmO2Y21g8o7Ax8uYbO0/edit#) first.

### Tools

For sake of simplicity and full automation, the entire code base, docker images and infrastructure can be built and provisioned from your laptop when you have the following 3 tools:

 * Docker
 * [Dojo](https://github.com/kudulab/dojo) - `brew install kudulab/homebrew-dojo-osx/dojo`
 * Make

On Mac, you can make sure you have all tools installed by running:

```
./recops.sh install_tools
```
### AWS access

AWS console access:

1. You can login to the AWS console by clicking the Okta Chicklet in your Okta Dashboard.
2. Switch role to `interviewer`. [Link](https://signin.aws.amazon.com/switchrole?roleName=interviewer&account=%3Center_account_id_here%3E)
3. Switch to `eu-west-1` (Ireland) region.

Hint: AWS account IDs for existing AWS recruiting accounts can be found in the [recops.sh](recops.sh) script.

For CLI access:

```sh
brew tap versent/homebrew-taps
brew install saml2aws
```

Run
```
eval $(./recops.sh login)
```

## Deployment in one go

```sh
make deploy_interview
```

*Warning:* It takes 16 minutes to deploy the infrastructure from scratch. So it is a good idea to start running `make deploy_interview` before pairing exercise begins.

**Making changes to deployment during interview:**

```sh
# Enter the docker container with terraform
dojo
# Change current directory to where the main terraform resources are
cd infra/news
# Run terraform as usual
terraform apply
```

At the end of the interview, clean up the cloud resources:

```sh
make destroy_interview
```

## Step by step deployment

Note: you need to avoid namespace clash with other people deploying from this codebase at the same time. Due to this, **please start by running randomization target first**:

```
make randomize
```

It will make the resources unique for your interview.

Now, for a more step by step deployment description please refer to [README.md](README.md).

# Implementation notes

 * Why we have remote terraform backend? So that CI can setup the infrastructure, then you can mangle with it from your laptop during the interview. Also so that candidate and interviewer can share state between 2 computers.
 * Docker images are built when setting up interview, then hosted by ECR because it is simpler than sharing images.
