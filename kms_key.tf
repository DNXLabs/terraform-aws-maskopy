resource "aws_kms_key" "maskopy_key" {
  provider = aws.source
  count    = var.enabled ? 1 : 0

  description             = "Maskopy KMS key 1"
  deletion_window_in_days = 10

  policy = data.aws_iam_policy_document.maskopy_key_policy.json
}

resource "aws_kms_alias" "maskopy_key" {
  provider = aws.source
  count    = var.enabled ? 1 : 0

  name          = "alias/Maskopy"
  target_key_id = aws_kms_key.maskopy_key[0].key_id
}

data "aws_iam_policy_document" "maskopy_key_policy" {
  statement {
    sid = "Enable IAM User Permissions"

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.source.account_id}:root"]
    }

    actions = [
      "kms:*",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "Allow access for Key Administrators"

    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.staging.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.staging.account_id}:role/${var.lambda_role_name}"
      ]
    }

    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "Allow use of the key"

    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.staging.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.staging.account_id}:role/${var.lambda_role_name}"
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "Allow attachment of persistent resources"

    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.staging.account_id}:root"
      ]
    }

    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]

    resources = [
      "*"
    ]

    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"

      values = [
        "true"
      ]
    }
  }
}
