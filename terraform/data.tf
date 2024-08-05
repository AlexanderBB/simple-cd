data "aws_caller_identity" "current" {}
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/broker.zip"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
  statement {
    actions = [
      "codebuild:StartBuild"
    ]
    resources = [
      "arn:aws:codebuild:${var.region}:${data.aws_caller_identity.current.account_id}:project/${local.codebuild_name}"
    ]
  }
  statement {
    sid = "GetLastVersionBeforeDelete"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:GetObject*",
      "s3:PutObject*"
    ]
    resources = [
      "arn:aws:s3:::${var.artefacts_bucket}",
      "arn:aws:s3:::${var.artefacts_bucket}/artefacts/*",
      "arn:aws:s3:::${var.artefacts_bucket}/tmp/*"
    ]
  }
  #   statement {
  #     sid = "MovingToTMP"
  #     actions = [
  #       "s3:ListBucket",
  #       "s3:ListBucketVersions",
  #       "s3:GetObject",
  #       "s3:PutObject",
  #       "s3:PutObjectAcl"
  #     ]
  #     resources = [
  #       "arn:aws:s3:::${var.artefacts_bucket}",
  #       "arn:aws:s3:::${var.artefacts_bucket}/tmp/*"
  #     ]
  #   }
}

data "aws_iam_policy_document" "codebuild_custom_policy" {
  statement {
    sid = "BasicExecutionRights"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
    ]
  }
  statement {
    sid = "AssumeDeploymentRole"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      var.deployment_role_arn
    ]
  }
  statement {
    sid = "ROAccessToArtefacts"
    actions = [
      "s3:List*",
      "s3:Get*"
    ]
    resources = [
      "arn:aws:s3:::${var.artefacts_bucket}",
      "arn:aws:s3:::${var.artefacts_bucket}/*"
    ]
  }
  statement {
    sid = "StateBucketAccess"
    actions = [
      "s3:List*",
      "s3:Get*",
      "s3:Put*"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket}",
      "arn:aws:s3:::${var.state_bucket}/terraform-states/*"
    ]
  }
  statement {
    sid = "RemoveTMPArtefacts"
    actions = [
      "s3:DeleteObject*"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket}/tmp/*"
    ]
  }
}
