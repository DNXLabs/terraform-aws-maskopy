resource "null_resource" "setup_lambda_layer" {
  count = (var.enabled && var.build_lambda_layer) ? 1 : 0

  triggers = {
    requirements = base64sha256(file("${path.module}/lambda/requirements.txt"))
  }

  provisioner "local-exec" {
    command = "${path.module}/setup-lambda-layer.sh"
  }
}

data "archive_file" "maskopy_lambda_layer_zip" {
  count = (var.enabled && var.build_lambda_layer) ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/lambda_layer_payload"
  output_path = "${path.module}/release/lambda_layer_payload.zip"

  depends_on = [null_resource.setup_lambda_layer]
}

resource "aws_lambda_layer_version" "maskopy_lambda_layer" {
  count    = var.enabled ? 1 : 0
  provider = aws.staging

  filename   = "${path.module}/release/lambda_layer_payload.zip"
  layer_name = "lambda_layer_maskopy"

  compatible_runtimes = ["python3.6"]

  depends_on = [
    null_resource.setup_lambda_layer
  ]
}

data "archive_file" "lambda_zip_file" {
  count = var.enabled ? length(var.lambdas_names) : 0

  type        = "zip"
  source_dir  = "${path.module}/lambda/${var.lambdas_names[count.index]}"
  output_path = "${path.module}/release/${var.lambdas_names[count.index]}.zip"
}

resource "aws_lambda_function" "source" {
  count    = var.enabled ? length(var.lambdas_names) : 0
  provider = aws.staging

  depends_on = [
    aws_iam_role_policy_attachment.maskopy_trust_lambda_role_attach
  ]

  filename         = "${path.module}/release/${var.lambdas_names[count.index]}.zip"
  source_code_hash = data.archive_file.lambda_zip_file[count.index].output_base64sha256
  function_name    = "MASKOPY-${var.lambdas_names[count.index]}"
  description      = "MASKOPY-${var.lambdas_names[count.index]}"
  role             = aws_iam_role.lambda_role[0].arn
  handler          = "index.lambda_handler"
  runtime          = "python3.6"
  timeout          = 25
  memory_size      = 1024

  layers = [
    aws_lambda_layer_version.maskopy_lambda_layer[0].arn
  ]

  tags = {
    ApplicationName = var.application_name
    CostCenter      = var.cost_center
  }

  vpc_config {
    subnet_ids         = var.staging_subnet_ids
    security_group_ids = [aws_security_group.maskopy_app[0].id]
  }

  tracing_config {
    mode = "PassThrough"
  }

  environment {
    variables = {
      HASH                                    = base64sha256(file("${path.module}/lambda/requirements.txt"))
      account_id                              = data.aws_caller_identity.staging.account_id                                                    # Destination account id staging
      accounts_to_share_with                  = data.aws_caller_identity.staging.account_id                                                    # Destination account id staging
      custom_kms_key                          = var.custom_source_kms_key_enabled ? var.custom_source_kms_key : aws_kms_key.maskopy_key[0].arn # masterAccessKeyArn
      destination_account_default_kms_key_arn = var.staging_rds_default_kms_key_id
      default_image                           = var.ecs_docker_image
      region                                  = data.aws_region.current.name
      security_group                          = aws_security_group.maskopy_db[0].id           # RDS security group on staging account
      service_role                            = aws_iam_role.maskopy_ecs_fargate_role[0].name # ECS service role
      assume_role_arn                         = aws_iam_role.maskopy_source_account_role[0].arn
      subnet_group_name                       = var.rds_staging_subnet_group_name
    }
  }

  lifecycle {
    ignore_changes = [source_code_hash]
  }
}
