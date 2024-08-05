variable "region" {
  description = "The deployment target region for the infrastructure"
  type        = string
  default     = "eu-west-1"
}

variable "state_bucket" {
  description = "The state bucket used to store the terraform state files, for this and the application deployments."
  type        = string
}

variable "lambda_source_bucket" {
  description = "This bucket will host the lambda source as s3 object."
  type        = string
}

variable "artefacts_bucket" {
  description = "The bucket which will provide the hosting of the artefacts."
  type        = string
}

variable "deployment_role_arn" {
  description = "The role used to deploy the web infrastructure to the deployment account"
  type        = string
}

variable "solution_name" {
  description = "The name of this solution"
  type        = string
  default     = "simple-cd"
}

variable "environment_name" {
  description = "The name of the environment in which this solution is deployed"
  type        = string
  default     = "dev"
}
