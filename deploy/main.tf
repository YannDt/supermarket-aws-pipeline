# ######################################################################################################################
# # S3 RESOURCES
# ######################################################################################################################

# Input Bucket
resource "aws_s3_bucket" "supermarket_s3_input_bucket" {
  bucket = "${var.organization_name}-${var.input_bucket_prefix}"
  acl    = "private"  
}

# Output Bucket
resource "aws_s3_bucket" "supermarket_s3_output_bucket" {
  bucket = "${var.organization_name}-${var.output_bucket_prefix}"
  acl    = "private"  
}



# ######################################################################################################################
# # SNS RESOURCES
# ######################################################################################################################

# SNS Topic
resource "aws_sns_topic" "supermarket_sns_topic" {
  name = "${var.organization_name}-${var.sns_prefix}"
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "supermarket_sns_topic_policy" {
  arn    = aws_sns_topic.supermarket_sns_topic.arn
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "example-statement",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "SNS:Publish",
      "Resource": "${aws_sns_topic.supermarket_sns_topic.arn}"
    }
  ]
}
EOF
}

# Enabling the bucket to notify the topic whenever an object is created in it.
resource "aws_s3_bucket_notification" "supermarket_bucket_notification" {
  bucket = "${aws_s3_bucket.supermarket_s3_input_bucket.id}"

  topic {
    topic_arn = aws_sns_topic.supermarket_sns_topic.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# ######################################################################################################################
# # SQS RESOURCES
# ######################################################################################################################

# SQS Queue
resource "aws_sqs_queue" "supermarket_sqs_queue" {
  name = "${var.organization_name}-${var.sqs_prefix}"
}

# Subscribing SQS queue to the SNS topic
resource "aws_sns_topic_subscription" "supermarket_sqs_target" {
  topic_arn = aws_sns_topic.supermarket_sns_topic.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.supermarket_sqs_queue.arn
}

# ######################################################################################################################
# # TRIGGER STEPFUNCTION LAMBDA RESOURCES
# ######################################################################################################################

# Lambda Code Compressing
data "archive_file" "supermarket_trigger_step_lambda_code" {
  type        = "zip"
  source_dir  = "src/lambdas/trigger_lambda"
  output_path = "trigger_step_code.zip"
}

# Lambda Function
resource "aws_lambda_function" "supermarket_trigger_step_lambda_function" {
  function_name    = "${var.organization_name}-${var.trigger_step_lambda_prefix}"
  handler          = "trigger_step.lambda_handler"
  runtime          = "python3.8"
  filename         = "${data.archive_file.supermarket_trigger_step_lambda_code.output_path}"
  source_code_hash = filebase64sha256("${data.archive_file.supermarket_trigger_step_lambda_code.output_path}")
  role             = aws_iam_role.supermarket_trigger_step_lambda_role.arn

    environment {
    variables = {
      stepfunction_arn = aws_sfn_state_machine.supermarket_stepfunction.arn
    }
  }
}

# Allowing SQS to start the trigger lambda function
resource "aws_lambda_permission" "sqs_permission_trigger_lambda" {
  statement_id  = "AllowSQSInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.supermarket_trigger_step_lambda_function.arn
  principal     = "sqs.amazonaws.com"

  source_arn = aws_sqs_queue.supermarket_sqs_queue.arn
}

# SQS trigger to the Trigger Lambda function
resource "aws_lambda_event_source_mapping" "supermarket_sqs_trigger_lambda_connection" {
  event_source_arn = aws_sqs_queue.supermarket_sqs_queue.arn
  function_name    = aws_lambda_function.supermarket_trigger_step_lambda_function.function_name
}


# ######################################################################################################################
# # PROCESSING LAMBDA RESOURCES
# ######################################################################################################################

# Lambda Code Compressing
data "archive_file" "supermarket_processing_lambda_code" {
  type        = "zip"
  source_dir  = "src/lambdas/processing_lambda"
  output_path = "processing_lambda_code.zip"
}

# Lambda Function
resource "aws_lambda_function" "supermarket_processing_lambda_function" {
  function_name    = "${var.organization_name}-${var.processing_lambda_prefix}"
  handler          = "processing_code.lambda_handler"
  runtime          = "python3.8"
  filename         = "${data.archive_file.supermarket_processing_lambda_code.output_path}"
  source_code_hash = filebase64sha256("${data.archive_file.supermarket_processing_lambda_code.output_path}")
  role             = aws_iam_role.supermarket_processing_lambda_role.arn
  timeout          = 60

    environment {
    variables = {
      output_bucket_name = aws_s3_bucket.supermarket_s3_output_bucket.id
    }
  }

  layers = ["arn:aws:lambda:${var.aws_region}:336392948345:layer:AWSDataWrangler-Python38:1"]
}

# Allowing StepFunction to start the processing lambda function
resource "aws_lambda_permission" "stepfunction_permission_processing_lambda" {
  statement_id  = "AllowStepFunctionInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.supermarket_processing_lambda_function.arn
  principal     = "states.amazonaws.com"

  source_arn = aws_sfn_state_machine.supermarket_stepfunction.arn
}
# ######################################################################################################################
# # GLUE RESOURCES
# ######################################################################################################################

# Glue Database
resource "aws_glue_catalog_database" "supermarket_glue_database" {
  name = "${var.organization_name}-${var.glue_database_prefix}"
}

# Glue Crawler
resource "aws_glue_crawler" "supermarket_glue_crawler" {
  database_name = aws_glue_catalog_database.supermarket_glue_database.name
  name          = "${var.organization_name}-${var.crawler_prefix}"
  role          = aws_iam_role.supermarket_crawler_role.arn

  s3_target {
    path = "${aws_s3_bucket.supermarket_s3_output_bucket.id}/data/"
  }
}

resource "aws_athena_workgroup" "supermarket_athena_workgroup" {
  name = "${var.organization_name}-${var.athena_workgroup_prefix}"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.supermarket_s3_output_bucket.id}/athena_query_results/"
    }
  }
}

# ######################################################################################################################
# # STEPFUNCTIONS RESOURCES
# ######################################################################################################################

resource "aws_sfn_state_machine" "supermarket_stepfunction" {
  name     = "${var.organization_name}-${var.stepfunction_prefix}"
  role_arn = aws_iam_role.supermarket_stepfunction_role.arn
  definition    = jsonencode(
      {
        StartAt = "StartProcessingLambda"
        States  = {
            StartCrawler          = {
                End        = true
                Parameters = {
                    Name = "${aws_glue_crawler.supermarket_glue_crawler.name}"
                }
                Resource   = "arn:aws:states:::aws-sdk:glue:startCrawler"
                Type       = "Task"
            }
            StartProcessingLambda = {
                Next       = "StartCrawler"
                OutputPath = "$.Payload"
                Parameters = {
                    FunctionName = "${aws_lambda_function.supermarket_processing_lambda_function.arn}:$LATEST"
                    "Payload.$"  = "$"
                }
                Resource   = "arn:aws:states:::lambda:invoke"
                Type       = "Task"
            }
        }
      }
  )
}