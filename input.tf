/* Common depedecies */
variable "alias" {}
variable "region" {}
variable "accountId" {}

# variable "apiParameters" { type = "list" } # add example

/* Lambda depedecies */
variable "lambda_publish" {}
variable "lambda_source_name" {}
variable "lambda_function_name" {}

/* API Gateway depedecies */
variable "api_gateway_name" {}
variable "api_gateway_description" {}
