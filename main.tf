/* TODO Add variables for support of swagger template of API */

module "lambda-default-iam" {
  source = "github.com/hashiops/tfmodule-lambda_default_iam"
}

resource "aws_lambda_function" "function" {
  count             = "${length(var.dataStructure)}"
  s3_bucket         = "${lookup(var.dataStructure[count.index],"lambda_function_s3_bucket")}"
  s3_key            = "${lookup(var.dataStructure[count.index],"lambda_function_source_path")}/${lookup(var.dataStructure[count.index],"lambda_function_source_name")}"
  function_name     = "${lookup(var.dataStructure[count.index],"lambda_function_name")}"
  role              = "${module.lambda-default-iam.lambda_role_arn}"
  handler           = "${lookup(var.dataStructure[count.index],"lambda_function_handler")}"
  runtime           = "${lookup(var.dataStructure[count.index],"lambda_function_runtime")}"
  publish           = "True"
}

resource "aws_lambda_alias" "alias" {
  count            = "${length(var.dataStructure)}"
  name             = "${lookup(var.dataStructure[count.index],"alias")}"
  function_name    = "${element(aws_lambda_function.function.*.arn, count.index)}"
  function_version = "${element(aws_lambda_function.function.*.version, count.index)}"
}

data "template_file" "swagger_api" {
  count    = "${length(var.dataStructure)}"
  template = "${file(lookup(var.dataStructure[count.index],"api_gateway_swagger_template_path"))}"

  vars {
    api_gateway_name = "${lookup(var.dataStructure[count.index],"api_gateway_name")}"
    api_gateway_description = "${lookup(var.dataStructure[count.index],"api_gateway_description")}"
    api_gateway_version = "${lookup(var.dataStructure[count.index],"api_gateway_version")}"
    api_gateway_endpoint_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${element(aws_lambda_alias.alias.*.arn, count.index)}/invocations"
    api_gateway_path = "${lookup(var.dataStructure[count.index],"api_gateway_path")}"
    api_gateway_method = "${lookup(var.dataStructure[count.index],"api_gateway_method")}"
    api_gateway_type = "${lookup(var.dataStructure[count.index],"api_gateway_type")}"
    api_gateway_dataType_input = "${lookup(var.dataStructure[count.index],"api_gateway_dataType_input")}"
    api_gateway_dataType_output = "${lookup(var.dataStructure[count.index],"api_gateway_dataType_output")}"
  }
}

resource "aws_api_gateway_rest_api" "RootAPI" {
  count       = "${length(var.dataStructure)}"
  name        = "${lookup(var.dataStructure[count.index],"api_gateway_name")}"
  description = "${lookup(var.dataStructure[count.index],"api_gateway_description")}"
  body        = "${element(data.template_file.swagger_api.*.rendered, count.index)}"
}

resource "aws_lambda_permission" "allow_api_gateway" {
  depends_on    = ["aws_api_gateway_rest_api.RootAPI"]
  count         = "${length(var.dataStructure)}"
  function_name = "${element(aws_lambda_function.function.*.arn, count.index)}"
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.accountId}:${element(aws_api_gateway_rest_api.RootAPI.*.id, count.index)}/*/${upper(lookup(var.dataStructure[count.index],"api_gateway_method"))}/${lookup(var.dataStructure[count.index],"api_gateway_path")}"
  qualifier     = "${element(aws_lambda_alias.alias.*.name, count.index)}"
}

resource "aws_api_gateway_deployment" "DeployAPI" {
  count       = "${length(var.dataStructure)}"
  rest_api_id = "${element(aws_api_gateway_rest_api.RootAPI.*.id, count.index)}"
  description = "Targets to ${element(aws_lambda_function.function.*.arn, count.index)}:${element(aws_lambda_alias.alias.*.name, count.index)}"
  stage_name  = "${element(aws_lambda_alias.alias.*.name, count.index)}"
}
