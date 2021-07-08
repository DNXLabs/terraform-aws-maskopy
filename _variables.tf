variable "enabled" {
  default     = true
  type        = bool
  description = "If true, will deploy the maskopy solution."
}

variable "build_lambda_layer" {
  default     = false
  type        = bool
  description = "If true will build the lambda layer. Set to true only with local source module."
}

variable "sqs_queue_name" {
  default     = "maskopy_sqs_queue"
  type        = string
  description = "SNS queue name to send messages when step functions complete running."
}

variable "cost_center" {
  type        = string
  default     = "MaskopyCost"
  description = "All the temporary resources are tagged with the code."
}

variable "staging_subnet_ids" {
  type        = list(string)
  description = "Subnets inside the staging VPC to deploy the lambdas and ECS tasks."
}

variable "staging_vpc_id" {
  type        = string
  description = "VPC id for the staging account."
}

variable "step_function_state_machine_name" {
  type        = string
  default     = "maskopy-state-machine"
  description = "Name for the step functions state machine."
}

variable "ecs_docker_image" {
  type        = string
  default     = "dnxsolutions/obfuscation"
  description = "Docker image that ECS task will run with and will download the scripts from S3 obfuscation bucket."
}

variable "rds_staging_subnet_group_name" {
  type        = string
  description = "Staging RDS option group name to deploy the transient database."
}

variable "lambda_role_name" {
  type        = string
  default     = "LAMBDA_MASKOPY"
  description = "Lambda role name."
}

variable "ecs_fargate_role_name" {
  type        = string
  default     = "ECS_MASKOPY"
  description = "ECS role name."
}

variable "staging_rds_default_kms_key_id" {
  type        = string
  description = "KMS key that maskopy will use for the transient RDS."
}

variable "custom_source_kms_key_enabled" {
  type        = bool
  default     = false
  description = "Only used when encrypt RDS in source account with another KMS key. Remember to add permissions to the existing key."
}

variable "custom_source_kms_key" {
  type        = string
  default     = ""
  description = "Custom KMS key, used when variable `custom_source_kms_key_enabled` equals to true."
}

variable "create_obfuscation_scripts_bucket" {
  type        = bool
  default     = true
  description = "Create bucket to store obfuscation scripts."
}

variable "obfuscation_scripts_bucket_name" {
  type        = string
  description = "Bucket to store the obfuscations scripts, they should be uploaded inside `/obfuscation` folder."
}

variable "replicate_obfuscation_bucket" {
  type        = bool
  default     = true
  description = "Replicate data inside the bucket to another acount."
}

variable "replicate_obfuscation_bucket_prefix" {
  type        = string
  default     = "dumps"
  description = "Name of prefix to replicate inside the bucket to another acount."
}

variable "replicate_destination_bucket_name" {
  type        = string
  default     = ""
  description = "Name of the bucket to send dumps data from source bucket."
}

variable "replicate_destination_account_id" {
  type        = string
  default     = ""
  description = "Name of the bucket to send dumps data from source bucket."
}

variable "application_name" {
  type        = string
  default     = "MASKOPY"
  description = "The name for the maskopy application, this name should match part of the string with the invoker role name."
}

variable "lambdas_names" {
  type = list(string)
  default = [
    "00-AuthorizeUser",
    "01-UseExistingSnapshot",
    "02-CheckForSnapshotCompletion",
    "03-ShareSnapshots",
    "04-CopySharedDBSnapshots",
    "05-CheckForDestinationSnapshotCompletion",
    "06-RestoreDatabases",
    "07-CheckForRestoreCompletion",
    "08a-CreateFargate",
    "08b-CreateECS",
    "09-TakeSnapshot",
    "10-CheckFinalSnapshotAvailability",
    "11-CleanupAndTagging",
    "ErrorHandlingAndCleanup"
  ]
}