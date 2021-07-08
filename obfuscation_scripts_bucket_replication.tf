resource "aws_s3_bucket" "source_snapshot_bucket" {
  count    = (var.enabled && var.create_obfuscation_scripts_bucket && var.replicate_obfuscation_bucket) ? 1 : 0
  provider = aws.staging

  bucket = var.obfuscation_scripts_bucket_name
  acl    = "private"

  versioning {
    enabled = true
  }

  replication_configuration {
    role = aws_iam_role.replication[0].arn

    rules {
      id       = "dumps"
      prefix   = var.replicate_obfuscation_bucket_prefix
      status   = "Enabled"
      priority = 0

      destination {
        bucket        = "arn:aws:s3:::${var.replicate_destination_bucket_name}"
        storage_class = "STANDARD"
        account_id    = var.replicate_destination_account_id
        access_control_translation {
          owner = "Destination"
        }
      }
    }
  }

  tags = {
    Tool = "MASKOPY"
  }
}

resource "aws_iam_role" "replication" {
  count = (var.enabled && var.create_obfuscation_scripts_bucket && var.replicate_obfuscation_bucket) ? 1 : 0

  name = "${var.obfuscation_scripts_bucket_name}-iam-role-replication"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  count = (var.enabled && var.create_obfuscation_scripts_bucket && var.replicate_obfuscation_bucket) ? 1 : 0

  name = "${var.obfuscation_scripts_bucket_name}-iam-role-policy-replication"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.obfuscation_scripts_bucket_name}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersionForReplication",
        "s3:GetObjectVersionAcl",
        "s3:GetObjectVersionTagging"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::${var.obfuscation_scripts_bucket_name}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete",
        "s3:ReplicateTags",
        "s3:ObjectOwnerOverrideToBucketOwner"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.replicate_destination_bucket_name}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication" {
  count = (var.enabled && var.create_obfuscation_scripts_bucket && var.replicate_obfuscation_bucket) ? 1 : 0

  role       = aws_iam_role.replication[0].name
  policy_arn = aws_iam_policy.replication[0].arn
}