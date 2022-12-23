locals {
  # Transform the bucket list into a map
  buckets_map = {
    for v in var.buckets :
    v.name => {
      id : format("%s-%s-%s", var.resource_prefix, v.name, var.aws_environment)
      acl : v.acl
      versioning : v.versioning
    }
  }
}

########################################################################################################################
## BUCKETS
########################################################################################################################
resource "aws_s3_bucket" "buckets" {
  for_each = local.buckets_map

  bucket = each.value.id
  force_destroy = true
}

########################################################################################################################
## BUCKETS VERSIONING
########################################################################################################################
resource "aws_s3_bucket_versioning" "buckets_versioning" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id
  versioning_configuration {
    status = local.buckets_map[each.key].versioning.status
  }
}

########################################################################################################################
## BUCKETS ACL
########################################################################################################################
resource "aws_s3_bucket_acl" "buckets_acl" {
  for_each = aws_s3_bucket.buckets

  bucket = each.value.id
  acl    = local.buckets_map[each.key].acl
}
