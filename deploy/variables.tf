variable "organization_name" {
  type    = string
  default = "yann-supermarket"
  description = "The organization name"
}

variable "aws_region" {
  type        = string
  default     = "us-east-1"
}

variable "input_bucket_prefix" {
  type    = string
  default = "input-bucket"
  description = "The bucket name"
}

variable "output_bucket_prefix" {
  type    = string
  default = "output-bucket"
  description = "The bucket name"
}

variable "sns_prefix" {
  type    = string
  default = "topic"
  description = "The SNS topic name"
}

variable "sqs_prefix" {
  type    = string
  default = "queue"
  description = "The SQS queue name"
}

variable "trigger_step_lambda_prefix" {
  type    = string
  default = "trigger-step"
  description = "The trigger step lambda function name"
}

variable "processing_lambda_prefix" {
  type    = string
  default = "processing"
  description = "The processing lambda function name"
}

variable "crawler_prefix" {
  type    = string
  default = "crawler"
  description = "The crawler name"
}

variable "glue_database_prefix" {
  type    = string
  default = "database"
  description = "The glue database name"
}

variable "athena_workgroup_prefix" {
  type    = string
  default = "workgroup"
  description = "The athena workgroup name"
}

variable "stepfunction_prefix" {
  type    = string
  default = "stepfunction"
  description = "The stepfunction name"
}