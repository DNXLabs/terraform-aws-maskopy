resource "aws_iam_role" "maskopy_source_account_role" {
  provider = aws.source
  count    = var.enabled ? 1 : 0

  name = "XACNT_MASKOPY"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.staging.account_id}:role/${var.lambda_role_name}"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Tool = "MASKOPY"
  }
}

resource "aws_iam_policy" "xacnt_maskopy_policy" {
  provider = aws.source
  count    = var.enabled ? 1 : 0

  name        = "xacnt-maskopy-policy"
  description = "XACNT maskopy policy"

  policy = data.aws_iam_policy_document.xacnt_maskopy_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "maskopy_source_account_policy_attachment" {
  provider = aws.source
  count    = var.enabled ? 1 : 0

  role       = aws_iam_role.maskopy_source_account_role[0].name
  policy_arn = aws_iam_policy.xacnt_maskopy_policy[0].arn
}

data "aws_iam_policy_document" "xacnt_maskopy_policy_doc" {
  statement {
    sid = "KMSandLogs"

    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "kms:List*",
      "kms:Get*",
      "kms:CreateAlias",
      "kms:Describe*",
      "kms:CreateKey",
      "kms:CreateGrant",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "RDSSnapshotPolicy"

    effect = "Allow"

    actions = [
      "rds:ListTagsForResource",
      "rds:DescribeDBSnapshots",
      "rds:CopyDBSnapshot",
      "rds:ModifyDBSnapshotAttribute",
      "rds:DescribeDBInstances",
      "rds:AddTagsToResource"
    ]

    resources = [
      "arn:aws:rds:*:${data.aws_caller_identity.source.account_id}:*:*"
    ]
  }

  statement {
    sid = "RDSDeletePolicy"

    effect = "Allow"

    actions = [
      "rds:DeleteDBSnapshot"
    ]

    resources = [
      "arn:aws:rds:*:${data.aws_caller_identity.source.account_id}:*:maskopy*"
    ]
  }
}
