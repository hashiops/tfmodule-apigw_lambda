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
variable "api_gateway_version" {}
variable "api_gateway_path" {}
variable "api_gateway_method" {}
variable "api_gateway_type" {}
variable "api_gateway_dataType_input" {}
variable "api_gateway_dataType_output" {}
