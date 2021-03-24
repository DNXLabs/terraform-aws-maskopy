resource "aws_iam_role" "maskopy_ecs_fargate_role" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  name = var.ecs_fargate_role_name

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com",
            "ecs-tasks.amazonaws.com",
            "ec2.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Tool = "MASKOPY"
  }
}

resource "aws_iam_policy" "maskopy_ecs_fargate_policy" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  name        = "maskopy_ecs_fargate_policy"
  description = ""
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "s3:Get*",
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:ListTagsForResource",
          "ecr:ListImages",
          "s3:List*",
          "ecr:GetRepositoryPolicy"
        ],
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Sid" : "RDSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "rds:DescribeDBSnapshots",
          "rds:CopyDBSnapshot",
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance",
          "rds:ModifyDBSnapshotAttribute"
        ],
        "Resource" : "arn:aws:rds:*:*:*:maskopy*"
      },
      {
        "Sid" : "KMSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "kms:EnableKey",
          "kms:Decrypt",
          "kms:ReEncryptFrom",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:ListKeys",
          "kms:Encrypt",
          "kms:ReEncryptTo",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ],
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:key/${var.staging_rds_default_kms_key_id}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "maskopy_trust_ecs_role_attach" {
  count    = var.enabled ? 1 : 0
  provider = aws.staging

  role       = aws_iam_role.maskopy_ecs_fargate_role[0].name
  policy_arn = aws_iam_policy.maskopy_ecs_fargate_policy[0].arn
}
