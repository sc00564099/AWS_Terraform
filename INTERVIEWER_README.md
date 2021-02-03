*Dear candidate, please ignore this document and read the README.md instead*

# TL;DR

**As an interviewer on the day of pairing**:

1. Make sure you have cloned a new copy of the joi-news-aws-na repository and all tools are installed:

```bash
$ ./recops.sh install_tools
```

2. Make sure you can access Okta Chiclet `AWS - NA Recruitment` and the AWS console.

3. Generate the credentials you and the candidate will use for the pairing exercise.  

```bash
$ export CODE_PREFIX=<candidate lastname>  # this should be in the meeting invite
$ eval $(./recops.sh login)
```

Use your ThoughtWorks Okta credentials. Select TOTP for mfa and provide the code.  

The AWS credentials to use during the interview should be part of the output from the above login command.  

```bash
{
    "AccessKey": {
        "AccessKeyId": "AK***",
        "SecretAccessKey": "ZGOL4*****",
        "Status": "Active",
        "UserName": "interview-smith",
        "CreateDate": "2021-01-30T21:42:49Z"
    }
}
```

Use these credentials yourself and provide them to the candidate at the start of the interview.  

4. Deploying the infrastructure and news application (it takes between 15-25 minutes) by running:

```bash
$ make deploy_interview
```

5. When it's time to pair with candidate, **you are responsible to give them AWS access**.  

**Zoom** Paste the above output containing temporary credentials into the Zoom chat. Confirm that the candidate already received the CODE_PREFIX and has localized their copy of the exercise.  

6. The candidate was asked to come prepared with one example improvement to the news app. Ask them to describe the change and attempt to apply.  


7. 

# IMPORTANT: Final Step

8. Tear down the news app infrastructure:  
  

```bash

```

Finally - from the AWS Consule delete the IAM User created for the candidate-interview.  
