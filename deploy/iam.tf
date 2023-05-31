# ######################################################################################################################
# # PROCESSING LAMBDA ROLE
# ######################################################################################################################

resource "aws_iam_role" "supermarket_processing_lambda_role" {
  name = "${var.organization_name}-${var.processing_lambda_prefix}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ######################################################################################################################
# # PROCESSING LAMBDA POLICY
# ######################################################################################################################

resource "aws_iam_policy" "supermarket_processing_lambda_policy" {
  name = "${var.organization_name}-${var.processing_lambda_prefix}-policy"
  description = "The ${var.organization_name} lambda IAM role policy."
  policy      = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AccessBucket",
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Effect": "Allow",
       "Resource":[             
       "${aws_s3_bucket.supermarket_s3_input_bucket.arn}",       
       "${aws_s3_bucket.supermarket_s3_input_bucket.arn}/*",
       "${aws_s3_bucket.supermarket_s3_output_bucket.arn}",
       "${aws_s3_bucket.supermarket_s3_output_bucket.arn}/*"
       ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],      
      "Resource": "*"
    },
    {
      "Sid": "AllowSQS",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl"
      ],
      "Resource": "${aws_sqs_queue.supermarket_sqs_queue.arn}"
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "supermarket_processing_lambda_policy_attachment" {
  role       = aws_iam_role.supermarket_processing_lambda_role.name
  policy_arn = aws_iam_policy.supermarket_processing_lambda_policy.arn
}

# ######################################################################################################################
# # TRIGGER STEP LAMBDA ROLE
# ######################################################################################################################

resource "aws_iam_role" "supermarket_trigger_step_lambda_role" {
  name = "${var.organization_name}-${var.trigger_step_lambda_prefix}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ######################################################################################################################
# # TRIGGER STEP LAMBDA POLICY
# ######################################################################################################################

resource "aws_iam_policy" "supermarket_trigger_step_lambda_policy" {
  name = "${var.organization_name}-${var.trigger_step_lambda_prefix}-policy"
  description = "The ${var.organization_name} lambda IAM role policy."
  policy      = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AccessBucket",
      "Action": [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject"
      ],
      "Effect": "Allow",
       "Resource":[             
       "${aws_s3_bucket.supermarket_s3_input_bucket.arn}",       
       "${aws_s3_bucket.supermarket_s3_input_bucket.arn}/*"
       ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],      
      "Resource": "*"
    },
    {
      "Sid": "AllowSQS",
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl"
      ],
      "Resource": "${aws_sqs_queue.supermarket_sqs_queue.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
          "states:StartExecution"
      ],
      "Resource": "${aws_sfn_state_machine.supermarket_stepfunction.arn}"
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "supermarket_trigger_step_lambda_policy_attachment" {
  role       = aws_iam_role.supermarket_trigger_step_lambda_role.name
  policy_arn = aws_iam_policy.supermarket_trigger_step_lambda_policy.arn
}

# ######################################################################################################################
# # CRAWLER ROLE
# ######################################################################################################################

resource "aws_iam_role" "supermarket_crawler_role" {
  name = "${var.organization_name}-${var.crawler_prefix}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ######################################################################################################################
# # CRAWLER POLICY
# ######################################################################################################################

resource "aws_iam_policy" "supermarket_crawler_policy" {
  name = "${var.organization_name}-${var.crawler_prefix}-policy"
  description = "The ${var.organization_name} crawler IAM role policy."
  policy      = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "",
        "Action": [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        "Effect": "Allow",
        "Resource":[             
            "${aws_s3_bucket.supermarket_s3_output_bucket.arn}",       
            "${aws_s3_bucket.supermarket_s3_output_bucket.arn}/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
            "glue:*",
            "s3:GetBucketLocation",
            "s3:ListBucket",
            "s3:ListAllMyBuckets",
            "s3:GetBucketAcl",
            "iam:ListRolePolicies",
            "iam:GetRole",
            "iam:GetRolePolicy",
            "cloudwatch:PutMetricData"
        ],
        "Resource": [
            "*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:CreateBucket"
        ],
        "Resource": [
            "arn:aws:s3:::aws-glue-*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject"
        ],
        "Resource": [
            "arn:aws:s3:::aws-glue-*/*",
            "arn:aws:s3:::*/*aws-glue-*/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject"
        ],
        "Resource": [
            "arn:aws:s3:::crawler-public*",
            "arn:aws:s3:::aws-glue-*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
        ],
        "Resource": [
            "arn:aws:logs:*:*:/aws-glue/*"
        ]
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "supermarket_crawler_policy_attachment" {
  role       = aws_iam_role.supermarket_crawler_role.name
  policy_arn = aws_iam_policy.supermarket_crawler_policy.arn
}

# ######################################################################################################################
# # SQS POLICY
# ######################################################################################################################

# SQS Queue Policy
resource "aws_sqs_queue_policy" "supermarket_sqs_queue_policy" {
  queue_url = aws_sqs_queue.supermarket_sqs_queue.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowLambdaInvocation",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.supermarket_sqs_queue.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${aws_sns_topic.supermarket_sns_topic.arn}"
        }
      }
    }
  ]
}
EOF
}

# ######################################################################################################################
# # STEPFUNCTION POLICY
# ######################################################################################################################

resource "aws_iam_role" "supermarket_stepfunction_role" {
  name = "${var.organization_name}-${var.stepfunction_prefix}-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "states.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# ######################################################################################################################
# # STEPFUNCTION POLICY
# ######################################################################################################################

resource "aws_iam_policy" "supermarket_stepfunction_policy" {
  name = "${var.organization_name}-${var.stepfunction_prefix}-policy"
  description = "The ${var.organization_name} stepfunction IAM role policy."
  policy      = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "StepFunctionLambdaPermissions",
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": [
       "${aws_lambda_function.supermarket_trigger_step_lambda_function.arn}*",
       "${aws_lambda_function.supermarket_processing_lambda_function.arn}*"
       ]
    },
    {
      "Sid": "StepFunctionGluePermissions",
      "Effect": "Allow",
      "Action": [
        "glue:StartCrawler",
        "glue:GetCrawler"
      ],
      "Resource": "${aws_glue_crawler.supermarket_glue_crawler.arn}"
    }
  ]
}
EOT
}

resource "aws_iam_role_policy_attachment" "supermarket_stepfunction_policy_attachment" {
  role       = aws_iam_role.supermarket_stepfunction_role.name
  policy_arn = aws_iam_policy.supermarket_stepfunction_policy.arn
}
