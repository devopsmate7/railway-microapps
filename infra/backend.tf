# Bucket, key, and region come from env/<env>/backend.hcl:
#   terraform init -backend-config=env/dev/backend.hcl
terraform {
  backend "s3" {}
}
