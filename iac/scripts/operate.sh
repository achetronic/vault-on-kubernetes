#!/usr/bin/env bash

# Set some params for the following things:
# 1. Print commands and arguments while they are executed
# 2. Force script to fail when any failure happens
#set -x
set -eo pipefail

# Defined to avoid relative-pathing issues
SELF_PATH=$(cd $(dirname "$0"); pwd)

#### FUNCTIONS DEFINITION ####
# Print a help message
function usage() {
  echo 'Usage: bash operate.sh -f FILE -o OPERATION [-a]'
  echo '-f Path to the Terraform tfvars file'
  echo '-o Terraform performed operation (apply or destroy)'
  echo '-a Use to auto approve on terraform operation'
  echo 'Example: bash operate.sh -f tfvars/foo.tfvars -o apply -a'
}

# Get the value of a variable from the tfvars file
function parse () {
  sed --quiet -E "s#^[[:blank:]]*(\b${1}\b){1}([[:blank:]]*\={1}[[:blank:]]*)(.*)#\3#p" "${TERRAFORM_TFVARS_PATH}" | tr -d '"'
}

# Copy the tfvars file to the place expected by Terraform modules
function copy_tfvars () {
    echo -e "\n\n======== Copying tfvars to Terraform directory ========\n\n"

    cp ${TERRAFORM_TFVARS_PATH} "${SELF_PATH}/../terraform/terraform.tfvars" || return $?

    echo "[ok] Copied successfully"
}

# Perform a Terraform init with several parameters preconfigured
function terraform_init () {
    terraform init \
     -reconfigure \
     -backend-config=bucket="${TFSTATE_BUCKET}" \
     -backend-config=profile="${AWS_ENVIRONMENT}" \
     -backend-config=key="${1}" \
     -backend-config=dynamodb_table="${TFSTATE_DYNAMODB_LOCKS_TABLE}" || return $?
}

# Deploy or destroy EKS resources
function perform_operation () {
    echo -e "\n\n======== Performing desired operation ========\n\n"

    cd "${SELF_PATH}/../terraform"

    # Init Terraform using a dedicated tfstate for EKS
    terraform_init "${TFSTATE_PATH}"

    # Execute crafted command
    # INFO: This command is crafted in the main flow of the script
    # WARNING: The comparison is required to get the exit code from eval command
    if ! eval "${CMD}"; then
      return 1
    fi

    # Go to the previous directory
    cd - || return $?
}

#### SCRIPT INITIAL CHECKS ####
while getopts f:o:ah option
do
    case "${option}"
    in
    f) TERRAFORM_TFVARS_PATH=${OPTARG};;
    o) TERRAFORM_OPERATION=${OPTARG};;
    a) TERRAFORM_AUTO_APPROVE="true";;
    *) usage
       exit 0;;
    esac
done

[ -z "${TERRAFORM_TFVARS_PATH}" ] && usage && exit 1
[ -z "${TERRAFORM_OPERATION}" ] || [[ ! "${TERRAFORM_OPERATION}" =~ (apply|destroy) ]] && usage && exit 1

#### VARIABLES DEFINITION ####
AWS_ENVIRONMENT=$(parse "aws_environment")
AWS_REGION=$(parse "aws_region")
ENVIRONMENT_CODE=${AWS_ENVIRONMENT:0:3}
TFSTATE_BUCKET="example-com-tfstate-${ENVIRONMENT_CODE}"
TFSTATE_DYNAMODB_LOCKS_TABLE="tfstate-locks-${ENVIRONMENT_CODE}"
TFSTATE_PATH="infrastructure/vault.tfstate"

#### SCRIPT EXECUTION ####
copy_tfvars

# Craft the command to be executed later
CMD="terraform ${TERRAFORM_OPERATION}"
[ "${TERRAFORM_AUTO_APPROVE:-"false"}" == "true" ] && CMD="${CMD} -auto-approve"

# Execute actions
if [ "${TERRAFORM_OPERATION}" == "apply" ]
then

  # Execute the Terraform code
  perform_operation || EXIT_CODE=$?

# On destroy, we need to destroy resources in a certain order to prevent leaving junk in the cloud.
elif [ "${TERRAFORM_OPERATION}" == "destroy" ]
then
  # Execute the Terraform code
  perform_operation || EXIT_CODE=$?

  # Remove EKS and its dependencies when:
  # 1. We can still get the kubeconfig: we can access the cluster
  # 2. The kubeconfig does not exist: the cluster is partially destroyed and we can not access the cluster
  aws s3 --profile "${AWS_ENVIRONMENT}" rm "s3://${TFSTATE_BUCKET}/${TFSTATE_PATH}";
  aws dynamodb delete-item \
    --table-name "${TFSTATE_DYNAMODB_LOCKS_TABLE}" \
    --key "{\"LockID\": {\"S\":\"${TFSTATE_BUCKET}/${TFSTATE_PATH}-md5\"}}" \
    --profile "${AWS_ENVIRONMENT}" \
    --region "${AWS_REGION}";
fi
