/* TODO Add variables for support of swagger template of API */

module "lambda-default-iam" {
  source = "github.com/hashiops/tfmodule-lambda_default_iam"
}

resource "aws_lambda_function" "function" {
  s3_bucket         = "sche-mcc-infra"
  s3_key            = "builds/${var.lambda_source_name}"
  function_name     = "${var.lambda_function_name}"
  role              = "${module.lambda-default-iam.lambda_role_arn}"
  handler           = "script.lambda_handler"
  runtime           = "python2.7"
  publish           = "${var.lambda_publish}"
}

resource "aws_lambda_alias" "alias" {
  name             = "hash_0"
  function_name    = "${aws_lambda_function.function.arn}"
  function_version = "${aws_lambda_function.function.version}"
}

data "template_file" "swagger_api" {
  template = "${file("swagger_api.yml")}"

  vars {
    some_variable = "test"
  }
}

resource "aws_api_gateway_rest_api" "RootAPI" {
  name        = "API NAME" # "${var.api_gateway_name}"
  description = "api description" # "${var.api_gateway_description}"
  body        = "${data.template_file.swagger_api.rendered}"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  function_name = "${aws_lambda_function.function.arn}"
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.RootAPI.id}/*/*/*"
  qualifier     = "${aws_lambda_alias.alias.name}"
}

resource "aws_api_gateway_deployment" "DeployAPI" {
  rest_api_id = "${aws_api_gateway_rest_api.RootAPI.id}"
  description = "Targets to ${aws_lambda_function.function.arn}:${aws_lambda_alias.alias.name}"
  stage_name  = "${aws_lambda_alias.alias.name}"
}
