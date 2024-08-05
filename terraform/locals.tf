locals {
  resource_name_prefix = "${var.solution_name}-${var.environment_name}"
  codebuild_name = "${local.resource_name_prefix}-terraform-deployment"
}
