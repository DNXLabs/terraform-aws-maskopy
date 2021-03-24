resource "aws_iam_role" "maskopy_invoker_role" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  name = "MASKOPY_INVOKER"

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
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.staging.account_id}:root"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Tool = "MASKOPY"
  }
}

resource "aws_iam_policy" "invoker_maskopy_policy" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  name        = "maskopy-invoker-role"
  description = "maskopy-invoker-role"
  policy      = data.aws_iam_policy_document.invoker_maskopy_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "maskopy_invoker_role_attachment" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  role       = aws_iam_role.maskopy_invoker_role[0].name
  policy_arn = aws_iam_policy.invoker_maskopy_policy[0].arn
}

data "aws_iam_policy_document" "invoker_maskopy_policy_doc" {
  statement {
    sid = "MaskopyPolicy"

    effect = "Allow"

    actions = [
      "states:StartExecution"
    ]

    resources = [
      aws_sfn_state_machine.sfn_state_machine[0].arn
    ]
  }
}
