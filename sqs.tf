resource "aws_sqs_queue" "maskopy_sqs_queue" {
  provider = aws.staging
  count    = var.enabled ? 1 : 0

  name = var.sqs_queue_name

  tags = {
    Tool = "maskopy"
  }
}