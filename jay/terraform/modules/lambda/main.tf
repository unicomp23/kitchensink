resource "aws_dynamodb_table" "log_tracker" {
  name         = "KafkaConsumerLogTracker"
  billing_mode = "PAY_PER_REQUEST" # Automatically adjusts capacity based on usage
  hash_key     = "folder_name"     # Partition key

  attribute {
    name = "folder_name"
    type = "S" # String
  }
}


resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.lambda_name}-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ],
        Resource = [
          "arn:aws:s3:::${var.bucket_name}/*"
        ]
      },
      {
        Effect   = "Allow",
        Action   = "s3:PutBucketNotification",
        Resource = "arn:aws:s3:::${var.bucket_name}"
      },
      {
        Effect   = "Allow",
        Action   = "s3:ListBucket",
        Resource = "arn:aws:s3:::${var.bucket_name}" # Bucket-level permission for ListBucket
      },
      {
        Action = [
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:PutItem"
        ]
        Effect   = "Allow",
        Resource = aws_dynamodb_table.log_tracker.arn,
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}
resource "aws_lambda_function" "single_lambda" {
  function_name = var.lambda_name
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_role.arn
  handler       = "analytics.lambda_handler" # Correct handler: file name and function name

  filename         = "${path.module}/function.zip"
  source_code_hash = filebase64sha256("${path.module}/function.zip")

  memory_size = var.memory_size
  timeout     = var.timeout

  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  # Add the ARN of the Pandas and NumPy Lambda Layer
  layers = [
    var.pandas_layer_arn
  ]

  environment {
    variables = {
      BUCKET_NAME    = var.bucket_name
      DYNAMODB_TABLE = aws_dynamodb_table.log_tracker.name
    }
  }
}

resource "aws_lambda_permission" "allow_s3_invocation" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.single_lambda.function_name
  principal     = "s3.amazonaws.com"

  source_arn = "arn:aws:s3:::${var.bucket_name}"
}

resource "aws_s3_bucket_notification" "s3_event_notification" {
  bucket = var.bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.single_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "consumer-logs-temp/"
    # filter_suffix       = "/"
  }

  depends_on = [
    aws_lambda_permission.allow_s3_invocation, # Ensure permissions are set before notification
    aws_lambda_function.single_lambda          # Ensure Lambda function exists
  ]
}