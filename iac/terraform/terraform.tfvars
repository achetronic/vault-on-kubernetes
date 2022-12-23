###############################################################
# Global variables
###############################################################
resource_prefix = "s3-bucket-example-com-vault"

###############################################################
# Account variables
###############################################################
iam_user        = "vault"
aws_environment = "develop"
aws_region      = "eu-west-1"

###############################################################
# Buckets variables
###############################################################
# Bucket list that will be created
buckets = [
  {
    name : "storage"
    acl : "private"
    versioning : {
      status : "Enabled"
    }
  }
]
