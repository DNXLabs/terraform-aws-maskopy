data "aws_caller_identity" "source" {
  provider = aws.source
}

data "aws_caller_identity" "staging" {
  provider = aws.staging
}

data "aws_region" "current" {}
