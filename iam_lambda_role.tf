resource "aws_iam_role" "lambda_role" {
  count    = var.enabled ? 1 : 0
  provider = aws.staging

  name = var.lambda_role_name

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com",
            "states.ap-southeast-2.amazonaws.com",
            "states.us-east-1.amazonaws.com",
            "states.us-east-2.amazonaws.com",
            "states.us-west-1.amazonaws.com",
            "sts.amazonaws.com",
            "states.us-west-2.amazonaws.com",
            "states.amazonaws.com",
            "events.amazonaws.com",
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

resource "aws_iam_policy" "maskopy_trust_lambda_role_policy" {
  count    = var.enabled ? 1 : 0
  provider = aws.staging

  name        = "maskopy_trust_lambda_role"
  description = "Trust Relationship for Lambda role."

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "MultiplePolicy",
        "Effect" : "Allow",
        "Action" : [
          "events:Put*",
          "events:DescribeRule",
          "ecs:CreateCluster",
          "s3:ListBucket",
          "ecs:DeregisterTaskDefinition",
          "ec2:DeleteNetworkInterface",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ecs:RegisterTaskDefinition",
          "rds:DescribeDBParameterGroups",
          "rds:DescribeDBSnapshots",
          "rds:DescribeDBInstances",
          "rds:DescribeOptionGroups",
          "rds:AddTagsToResource"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "RDSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "rds:CreateDBSnapshot",
          "rds:RestoreDBInstanceFromDBSnapshot"
        ],
        "Resource" : [
          "arn:aws:rds:*:*:*:*maskopy*",
          "arn:aws:rds:*:*:pg:*",
          "arn:aws:rds:*:*:subgrp:${var.rds_staging_subnet_group_name}"
        ]
      },
      {
        "Sid" : "PassRolePolicy",
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "arn:aws:iam::${data.aws_caller_identity.staging.account_id}:role/*MASKOPY*"
      },
      {
        "Sid" : "RDSMaskopyPolicy",
        "Effect" : "Allow",
        "Action" : "rds:*",
        "Resource" : [
          "arn:aws:rds:*:*:db:maskopy*",
          "arn:aws:rds:*:*:snapshot:*maskopy*"
        ]
      },
      {
        "Sid" : "KMSPolicy",
        "Effect" : "Allow",
        "Action" : [
          "kms:RevokeGrant",
          "kms:CreateGrant",
          "kms:ListGrants"
        ],
        "Resource" : [
          "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:key/${var.staging_rds_default_kms_key_id}",
          "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.source.account_id}:key/${aws_kms_key.maskopy_key[0].id}"
        ],
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      },
      {
        "Sid" : "MaskopyLambdaPolicy",
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole",
          "kms:Decrypt",
          "ecs:RunTask",
          "kms:Encrypt",
          "sqs:SendMessage",
          "kms:DescribeKey",
          "ecs:StartTask",
          "ecs:DeleteCluster",
          "kms:RetireGrant",
          "ecs:DescribeTasks",
          "ecs:DescribeClusters"
        ],
        "Resource" : [
          "arn:aws:iam::*:role/XACNT_MASKOPY",
          "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:key/${var.staging_rds_default_kms_key_id}",
          "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.source.account_id}:key/${aws_kms_key.maskopy_key[0].id}",
          "arn:aws:ecs:*:${data.aws_caller_identity.staging.account_id}:task-definition/*:*",
          "arn:aws:ecs:*:${data.aws_caller_identity.staging.account_id}:cluster/*",
          "arn:aws:ecs:*:${data.aws_caller_identity.staging.account_id}:task/*",
          "arn:aws:sqs:*:*:*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.staging.account_id}:log-group:/aws/lambda/MASKOPY-*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "lambda:InvokeAsync",
          "lambda:InvokeFunction"
        ],
        "Resource" : [
          "*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "maskopy_trust_lambda_role_attach" {
  count    = var.enabled ? 1 : 0
  provider = aws.staging

  role       = aws_iam_role.lambda_role[0].name
  policy_arn = aws_iam_policy.maskopy_trust_lambda_role_policy[0].arn
}