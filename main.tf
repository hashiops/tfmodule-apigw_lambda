/* TODO Add variables for support of swagger template of API */

module "lambda-default-iam" {
  source = "github.com/hashiops/tfmodule-lambda_default_iam"
}

resource "aws_lambda_function" "function" {
  function_name     = "${lookup(var.dataStructure,"lambda_function_name")}"
  role              = "${module.lambda-default-iam.lambda_role_arn}"
  handler           = "${lookup(var.dataStructure,"lambda_function_handler")}"
  runtime           = "${lookup(var.dataStructure,"lambda_function_runtime")}"
  filename          = "source.zip"

  lifecycle = {
    ignore_changes = ["filename"]
  }
}

resource "aws_api_gateway_rest_api" "RootAPI" {
  name        = "${lookup(var.dataStructure,"api_gateway_name")}"
  description = "${lookup(var.dataStructure,"api_gateway_description")}"
}

# resource "aws_lambda_permission" "allow_api_gateway" {
#   depends_on    = ["aws_api_gateway_rest_api.RootAPI"]
#   function_name = "${aws_lambda_function.function.arn}"
#   statement_id  = "AllowExecutionFromApiGateway"
#   action        = "lambda:InvokeFunction"
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "arn:aws:execute-api:${var.region}:${var.accountId}:${element(aws_api_gateway_rest_api.RootAPI.*.id, count.index)}/*/${upper(lookup(var.dataStructure[count.index],"api_gateway_method"))}/${lookup(var.dataStructure[count.index],"api_gateway_path")}"
#   qualifier     = "${element(aws_lambda_alias.alias.*.name, count.index)}"
# }
