########################################################################################################################
## GLOBAL VARIABLES
########################################################################################################################
variable "resource_prefix" {
  type        = string
  description = "Prefix for the name of the resources."
  default     = null
}

########################################################################################################################
## ACCOUNT VARIABLES
########################################################################################################################
variable "iam_user" {
  type        = string
  description = "IAM user to manage the gitlab resources."
  default     = null
}

variable "aws_environment" {
  type        = string
  description = "Environment where the resources are created."
  default     = "develop"
}

variable "aws_region" {
  description = "The AWS region to create the resources."
  default     = "eu-west-1"
}

########################################################################################################################
## BUCKETS VARIABLES
########################################################################################################################
variable "buckets" {
  type = list(object({
    name : string,
    acl : string,
    versioning : object({
      status : string
    })
  }))
  description = "List of buckets."
  default     = []
}
