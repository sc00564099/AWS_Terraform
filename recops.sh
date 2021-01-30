#!/usr/bin/env bash
set -Eeuo pipefail
source ./randomize.sh

RELEASER_VERSION="2.1.0"
RELEASER_FILE="ops/releaser-${RELEASER_VERSION}"

# Function to set TW Region specific Okta App URL & AWS role ARN

get_regional_okta_aws_info () {
  # declare -A AWS_OKTA_APP_IDS
  # AWS_OKTA_APP_IDS=(
  #   ["UK"]="0oa1hok6wfq5HpBgj0h8"
  #   ["DE"]="0oa1ih2bgpegSfjAt0h8"
  #   ["BR"]="0oa1ippx4gkbFqAwu0h8"
  #   ["CL"]="0oa1j9f9lg5IajjjC0h8"
  #   ["IN"]="0oa1jcifughse4NNr0h8"
  #   ["NA"]="0oa1k2cq1z9hZWsuZ0h8"
  # )

  # declare -A AWS_ACCOUNT_IDS
  # AWS_ACCOUNT_IDS=(
  #   ["UK"]="339270093312"
  #   ["DE"]="841586536262"
  #   ["BR"]="312992697307"
  #   ["CL"]="856054656601"
  #   ["IN"]="898060563170"
  #   ["NA"]="671609974945"
  # )

  # read -r -n 1 -p $'Select your TW region:
  #   1 -> UK
  #   2 -> DE
  #   3 -> BR
  #   4 -> CL
  #   5 -> IN
  #   6 -> NA
  # \n' \
  # GET_REGION;

  # case $GET_REGION in
  #     1)
  #         local TW_REGION=UK;;
  #     2)
  #         local TW_REGION=DE;;
  #     3)
  #         local TW_REGION=BR;;
  #     4)
  #         local TW_REGION=CL;;
  #     5)
  #         local TW_REGION=IN;;
  #     6)
  #         local TW_REGION=NA;;
  #     *)
  #         exit;;
  # esac

  local TW_REGION=NA
  echo "TW_REGION=NA" > .env-regional

  local AWS_OKTA_APP_ID=671609974945
  export OKTA_APP_URL=https://thoughtworks.okta.com/home/amazon_aws/0oa1k2cq1z9hZWsuZ0h8/272
  export AWS_ROLE_ARN=arn:aws:iam::671609974945:role/federated-admin
}

source_regional_config () {
  # shellcheck disable=SC1091
  [ -f .env-regional ] && source .env-regional
  : "${TW_REGION?TW Region not set, run login}"
}

##

#TODO: could be restricted to disallow breaking supporting infrastructure
INTERVIEW_POLICY=arn:aws:iam::aws:policy/AdministratorAccess

function source_releaser {
  mkdir -p ops
  if [[ ! -f $RELEASER_FILE ]];then
    wget --quiet -O $RELEASER_FILE https://github.com/kudulab/releaser/releases/download/${RELEASER_VERSION}/releaser
  fi
  source $RELEASER_FILE
}

function install_prerequisites {
  set +e
  if ! brew --version
  then
    echo "brew not found" >&2
    exit 5
  fi
  brew install kudulab/homebrew-dojo-osx/dojo
  brew tap versent/homebrew-taps
  brew install saml2aws
  brew install jq
}

# Publishes zip which recruiters distribute to the candidates when scheduling the interview.
# This is immutable and should not be deleted.
# We are sending a link to this S3 url to the candidates in emails.
function publish_generic_candidate_zip {
  #version=$(releaser::get_last_version_from_whole_changelog "${changelog_file}")
  version="2.1.0"
  file="infra-problem-${version}.zip"
  file_latest="infra-problem-latest.zip"
  echo $file
  zip -r "${file}" ./ -x "${file}" -x "*.zip" -x "./ops/*" -x ".git/*" -x "./INTERVIEWER_README.md" -x "./recops.sh" -x "./CHANGELOG.md"
  aws s3 cp "${file}" s3://tw-joii-nan/
  #aws s3 cp s3://tw-joii-nan/"${file}" s3://tw-joii-nan/"${file_latest}"
}

# Publishes zip which interviewers use when they don't have access to github recops
function publish_generic_interviewer_zip(){
  version=$(releaser::get_last_version_from_whole_changelog "${changelog_file}")
  file="infra-problem-${version}-full.zip"
  file_latest="infra-problem-latest-full.zip"
  zip -r "${file}" ./ -x "${file}" -x "*.zip"
  aws s3 cp "${file}" s3://tw-joi-nan/
  aws s3 cp s3://tw-joii/"${file}" s3://tw-joii/"${file_latest}"
}

# In case you want to share your local changes with the candidate
function publish_candidate_zip {
  >&2 echo "Preparing zip package for candidate"
  source_regional_config
  INTERVIEW_CODE=$(cat interview_id.txt)
  REGIONAL_S3_BUCKET=tw-joii-$(echo "${TW_REGION}n" | awk '{print tolower($0)}')
  file="./infra-problem-$INTERVIEW_CODE.zip"
  >&2 zip -r "${file}" ./ -x "${file}" -x "./ops/*" -x ".git/*" -x "./INTERVIEWER_README.md" -x "./recops.sh" -x "./CHANGELOG.md" > /dev/null
  >&2 echo "Publishing artifact to s3 bucket..."
  if ! aws s3 cp "${file}" s3://"${REGIONAL_S3_BUCKET}"/ > /dev/null
  then
    >&2 echo "Artifact preparation for candidate interview failed."
    exit 5
  else
    S3_URL="https://${REGIONAL_S3_BUCKET}.s3-eu-west-1.amazonaws.com/${file}"
    >&2 echo "Artifact is prepared and available at $S3_URL"
    echo "$S3_URL"
  fi
}

function setup_user {
  # Create temporary user for the interview
  >&2 echo "Creating temporary user for the interview"
  >&2 USER_CREDS=$(dojo "./recops.sh _setup_creds")
  >&2 echo "$USER_CREDS"
  # AWS_SECRET_ACCESS_KEY=$(echo "$USER_CREDS" | jq -r '.AccessKey.SecretAccessKey')
  # AWS_ACCESS_KEY_ID=$(echo "$USER_CREDS" | jq -r '.AccessKey.AccessKeyId')
  # # Parent shell will source these user credentials
  # >&2 echo "Please export & unset the following in your shell, if not done automatically:"
  # >&2 echo "-----------------------------------------------------------------------------"
  # >&2 echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
  # >&2 echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
  # >&2 echo "unset AWS_SESSION_TOKEN"
  # >&2 echo ""
  # >&2 echo "Credentials that you can share with the candidate:"
  # >&2 echo "--------------------------------------------------"
  # >&2 echo "export CODE_PREFIX=$CODE_PREFIX"
  # >&2 echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
  # >&2 echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
}

check_if_clean_login () {
  if [ -f interview_id.txt ]; then
    >&2 echo "Looks like you are already logged in!"
    >&2 echo "Otherwise, please remove \"interview_id.txt\" file first."
    >&2 echo "And make sure you don't have any local changes."
    exit 0
  fi
}

if [ "$#" -eq 0 ]; then
  echo "Error: need to specify a command to run."
  exit 1
fi

command="$1"
case "${command}" in
  install_tools)
      install_prerequisites
      ;;
  candidate_prep)
      dojo "./recops.sh _candidate_prep"
      ;;
  _candidate_prep)
      echo "Here is all you need to share with the candidate:"
      echo ""
      echo "Hi there! Here are your credentials:"
      echo ""
      echo "export CODE_PREFIX=$CODE_PREFIX"
      echo "export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY"
      echo "export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID"
      echo ""
      echo "See README.md for more instructions."
      echo ""
      echo "Please email above to the candidate."
      ;;
  prepare_candidate_zip)
      S3_URL=$(publish_candidate_zip)
      echo "Please share this link to unique zip containing codebase with the candidate:"
      echo "$S3_URL"
      ;;
  _create_tmp_user)
      check_randomized
      INTERVIEW_CODE=$(cat interview_id.txt)
      >&2 aws iam create-user --user-name "interview-$INTERVIEW_CODE"
      >&2 aws iam attach-user-policy --policy-arn $INTERVIEW_POLICY --user-name "interview-$INTERVIEW_CODE"
      ;;
  _create_user_creds)
      check_randomized
      INTERVIEW_CODE=$(cat interview_id.txt)
      >&2 aws iam create-access-key --user-name "interview-$INTERVIEW_CODE"
      ;;
  _setup_creds)
      randomize
      ./recops.sh _create_tmp_user
      ./recops.sh _create_user_creds
      ;;
  login)
      unset AWS_SECRET_ACCESS_KEY
      unset AWS_ACCESS_KEY_ID
      unset AWS_SESSION_TOKEN
      check_if_clean_login
      get_regional_okta_aws_info
      source_regional_config
      >&2 saml2aws login --force \
        --url "$OKTA_APP_URL" \
        --idp-provider Okta \
        --mfa Auto \
        --profile infra-joi-"${TW_REGION}"
      ./recops.sh setup_access
      ;;
  _assume_role)
      source_regional_config
      aws sts assume-role --profile infra-joi-"${TW_REGION}" \
        --role-arn $AWS_ROLE_ARN \
        --role-session-name "$DOJO_USER"@"$HOSTNAME"
      ;;
  setup_access)
      SECRET_JSON=$(dojo "./recops.sh _assume_role")
      AWS_SECRET_ACCESS_KEY=$(echo "$SECRET_JSON" | jq -r '.Credentials.SecretAccessKey')
      AWS_ACCESS_KEY_ID=$(echo "$SECRET_JSON" | jq -r '.Credentials.AccessKeyId')
      AWS_SESSION_TOKEN=$(echo "$SECRET_JSON" | jq -r '.Credentials.SessionToken')
      # Assume interviewer role by exporting env variables
      export AWS_SECRET_ACCESS_KEY
      export AWS_ACCESS_KEY_ID
      export AWS_SESSION_TOKEN
      # Create a temporary user and assume its credentials
      setup_user
      ;;
  setup_user)
      setup_user
      ;;
  _randomize)
      randomize
      ;;
  randomize)
      dojo "./recops.sh _randomize"
      ;;
  verify_version)
      source_releaser
      releaser::verify_release_ready
      ;;
  # Releases this git repo
  release)
      ./recops.sh verify_version
      source_releaser
      version=$(releaser::get_last_version_from_whole_changelog "${changelog_file}")
      git tag "${version}" && git push origin "${version}"
      ;;
  # Publish the zip to AWS S3 to distribute among candidates
  publish)
      dojo "./recops.sh _publish"
      ;;
  _publish)
      source_releaser
      publish_generic_candidate_zip
      publish_generic_interviewer_zip
      ;;
  *)
      echo "Invalid command: '${command}'"
      exit 1
      ;;
esac

