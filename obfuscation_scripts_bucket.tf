resource "aws_s3_bucket" "obfuscation_scripts_bucket" {
  count    = (var.enabled && var.create_obfuscation_scripts_bucket && var.replicate_obfuscation_bucket == false) ? 1 : 0
  provider = aws.staging

  bucket = var.obfuscation_scripts_bucket_name
  acl    = "private"

  tags = {
    Tool = "MASKOPY"
  }
}