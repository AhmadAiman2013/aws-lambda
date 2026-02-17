terraform {
  backend "s3" {
    bucket       = "ahmad-aws-terraform"
    key          = "aws-test/terraform.tfstate"
    region       = "ap-southeast-1"
    encrypt      = true
    use_lockfile = true
  }
}