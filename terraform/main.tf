resource "aws_iam_role" "lambda_role" {
  name = "${local.resource_name_prefix}-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "lambda_policy_attachment" {
  name   = "lambda-policy-attachment"
  role   = aws_iam_role.lambda_role.id
  policy = data.aws_iam_policy_document.lambda_policy.json
}

resource "aws_iam_role" "codebuild_role" {
  name = "${local.resource_name_prefix}-codebuild"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "codebuild_custom_policy_attachment" {
  name   = "codebuild-custom-policy-attachment"
  role   = aws_iam_role.codebuild_role.id
  policy = data.aws_iam_policy_document.codebuild_custom_policy.json
}

resource "aws_lambda_function" "broker" {
  function_name = "${local.resource_name_prefix}-broker"
  handler       = "broker.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.lambda_role.arn
  environment {
    variables = {
      STATE_BUCKET           = var.state_bucket
      CODEBUILD_NAME         = local.codebuild_name
      TERRAFORM_STATE_PREFIX = "terraform-states"
    }
  }


  s3_bucket        = var.lambda_source_bucket
  s3_key           = "${local.resource_name_prefix}/src-files/broker.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_lambda_permission" "s3_event_permissions" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.broker.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.lambda_source_bucket}"
  statement_id  = "events-from-s3"

  lifecycle {
    replace_triggered_by = [
      aws_lambda_function.broker
    ]
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.artefacts_bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.broker.arn
    events = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    filter_prefix       = "artefacts"
    filter_suffix       = ".zip"
  }
  depends_on = [aws_lambda_function.broker]
}

resource "aws_codebuild_project" "terraform_cd" {
  name         = local.codebuild_name
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:5.0"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "STATE_BUCKET"
      value = var.state_bucket
    }

    environment_variable {
      name  = "DEPLOYMENT_ENV"
      value = var.environment_name
    }
  }

  source {
    type = "NO_SOURCE"
    buildspec = file("lambda/buildspecs/apply.yml")
  }
}

resource "aws_s3_object" "lambda_zip" {
  bucket = var.lambda_source_bucket
  key    = "${local.resource_name_prefix}/src-files/broker.zip"
  source = data.archive_file.lambda_zip.output_path
  etag = filemd5(data.archive_file.lambda_zip.output_path)
}
