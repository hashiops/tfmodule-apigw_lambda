/* TODO Add variables for support of swagger template of API */

module "lambda-default-iam" {
  source = "github.com/hashiops/tfmodule-lambda_default_iam"
}

# resource "aws_lambda_function" "function" {
#   count             = "${length(var.dataStructure)}"
#   s3_bucket         = "${lookup(var.dataStructure[count.index],"lambda_function_s3_bucket")}"
#   s3_key            = "${lookup(var.dataStructure[count.index],"lambda_function_source_path")}/${lookup(var.dataStructure[count.index],"lambda_function_source_name")}"
#   function_name     = "${lookup(var.dataStructure[count.index],"lambda_function_name")}"
#   role              = "${module.lambda-default-iam.lambda_role_arn}"
#   handler           = "${lookup(var.dataStructure[count.index],"lambda_function_handler")}"
#   runtime           = "${lookup(var.dataStructure[count.index],"lambda_function_runtime")}"
#   publish           = "True"
# }

resource "aws_lambda_function" "function" {
  s3_bucket         = "${lookup(var.dataStructure[length(var.dataStructure) - 1],"lambda_function_s3_bucket")}"
  s3_key            = "${lookup(var.dataStructure[length(var.dataStructure) - 1],"lambda_function_source_path")}/${lookup(var.dataStructure[length(var.dataStructure) - 1],"lambda_function_source_name")}"
  function_name     = "${lookup(var.dataStructure[length(var.dataStructure) - 1],"lambda_function_name")}"
  role              = "${module.lambda-default-iam.lambda_role_arn}"
  handler           = "${lookup(var.dataStructure[length(var.dataStructure) - 1],"lambda_function_handler")}"
  runtime           = "${lookup(var.dataStructure[length(var.dataStructure) - 1],"lambda_function_runtime")}"
  publish           = "True"
}

# resource "aws_lambda_alias" "alias" {
#   count            = "${length(var.dataStructure)}"
#   name             = "${lookup(var.dataStructure[count.index],"alias")}"
#   function_name    = "${element(aws_lambda_function.function.*.arn, count.index)}"
#   function_version = "${element(aws_lambda_function.function.*.version, count.index)}"
# }

resource "aws_lambda_alias" "alias" {
  name             = "${lookup(var.dataStructure[length(var.dataStructure) - 1],"alias")}"
  function_name    = "${aws_lambda_function.function.arn}"
  function_version = "${aws_lambda_function.function.version}"
}

# data "template_file" "swagger_api" {
#   count    = "${length(var.dataStructure)}"
#   template = "${file(lookup(var.dataStructure[count.index],"api_gateway_swagger_template_path"))}"
#
#   vars {
#     api_gateway_name = "${lookup(var.dataStructure[count.index],"api_gateway_name")}"
#     api_gateway_description = "${lookup(var.dataStructure[count.index],"api_gateway_description")}"
#     api_gateway_version = "${lookup(var.dataStructure[count.index],"api_gateway_version")}"
#     api_gateway_endpoint_uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${element(aws_lambda_alias.alias.*.arn, count.index)}/invocations"
#     api_gateway_path = "${lookup(var.dataStructure[count.index],"api_gateway_path")}"
#     api_gateway_method = "${lookup(var.dataStructure[count.index],"api_gateway_method")}"
#     api_gateway_type = "${lookup(var.dataStructure[count.index],"api_gateway_type")}"
#     api_gateway_dataType_input = "${lookup(var.dataStructure[count.index],"api_gateway_dataType_input")}"
#     api_gateway_dataType_output = "${lookup(var.dataStructure[count.index],"api_gateway_dataType_output")}"
#   }
# }

# resource "aws_api_gateway_rest_api" "RootAPI" {
#   count       = "${length(var.dataStructure)}"
#   name        = "${lookup(var.dataStructure[count.index],"api_gateway_name")}"
#   description = "${lookup(var.dataStructure[count.index],"api_gateway_description")}"
#   body        = "${element(data.template_file.swagger_api.*.rendered, count.index)}"
# }

resource "aws_api_gateway_rest_api" "RootAPI" {
  name        = "${lookup(var.dataStructure[length(var.dataStructure) - 1],"api_gateway_name")}"
  description = "${lookup(var.dataStructure[length(var.dataStructure) - 1],"api_gateway_description")}"
}

resource "aws_api_gateway_resource" "Resource" {
  count       = "${length(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_path")))}"
  rest_api_id = "${aws_api_gateway_rest_api.RootAPI.id}"
  parent_id   = "${aws_api_gateway_rest_api.RootAPI.root_resource_id}"
  path_part   = "${element(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_path")), count.index)}"
}

resource "aws_api_gateway_method" "Method" {
  count         = "${length(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_method")))}"
  rest_api_id   = "${aws_api_gateway_rest_api.RootAPI.id}"
  resource_id   = "${element(aws_api_gateway_resource.Resource.*.id, count.index)}"
  http_method   = "${upper(element(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_method")), count.index))}"
  authorization = "${upper(element(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_method_authorization")), count.index))}"
}

resource "aws_api_gateway_integration" "LambdaIntegration" {
  # depends_on  = ["aws_lambda_alias.alias"]
  count       = "${length(var.dataStructure)}"
  rest_api_id = "${aws_api_gateway_rest_api.RootAPI.id}"
  resource_id = "${element(aws_api_gateway_resource.Resource.*.id, index(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_target")), "lambda"))}"
  http_method = "${element(aws_api_gateway_method.Method.*.http_method, index(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_target")), "lambda"))}"
  integration_http_method = "${upper(element(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_method")), index(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_target")), "lambda")))}"
  type = "${upper(element(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_type")), index(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_target")), "lambda")))}"
  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.function.qualified_arn}/invocations"
  #uri = "${count.index != length(var.dataStructure) - 1 ? element(self.*.uri, count.index) : replace(replace("arn:aws:apigateway:REGION:lambda:path/2015-03-31/functions/LAMBDA_ARN/invocations", REGION, var.region), LAMBDA_ARN, aws_lambda_function.function.qualified_arn)}"

  lifecycle {
    ignore_changes = [ "${count.index != length(var.dataStructure) - 1 ? "uri" : ""}" ]
  }
}

/* NOTE
replace(string, search, replace) - Does a search and replace on the given string.
All instances of search are replaced with the value of replace. If search is wrapped
in forward slashes, it is treated as a regular expression. If using a regular
expression, replace can reference subcaptures in the regular expression by
using $n where n is the index or name of the subcapture. If using a regular expression,
the syntax conforms to the re2 regular expression syntax.
*/

resource "aws_api_gateway_integration" "ExternalIntegration" {
  # depends_on  = ["aws_lambda_alias.alias"]
  # count       = "${length(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_method")))}"
  rest_api_id = "${aws_api_gateway_rest_api.RootAPI.id}"
  resource_id = "${element(aws_api_gateway_resource.Resource.*.id, index(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_target")), "external"))}"
  http_method = "${element(aws_api_gateway_method.Method.*.http_method, index(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_target")), "external"))}"
  integration_http_method = "${upper(element(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_method")), index(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_target")), "external")))}"
  type = "${upper(element(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_type")), index(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_target")), "external")))}"
  uri = "${lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_external_uri")}"
}

/* NOTE maybe some additional integration resources will be required */

resource "aws_api_gateway_method_response" "Code200" {
  count       = "${length(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_path")))}"
  rest_api_id = "${aws_api_gateway_rest_api.RootAPI.id}"
  resource_id = "${element(aws_api_gateway_resource.Resource.*.id, count.index)}"
  http_method = "${element(aws_api_gateway_method.Method.*.http_method, count.index)}"
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "ResponseIntegration" {
  depends_on  = ["aws_api_gateway_method_response.Code200"]
  count       = "${length(split(",", lookup(var.dataStructure[length(var.dataStructure) - 1], "api_gateway_path")))}"
  rest_api_id = "${aws_api_gateway_rest_api.RootAPI.id}"
  resource_id = "${element(aws_api_gateway_resource.Resource.*.id, count.index)}"
  http_method = "${element(aws_api_gateway_method.Method.*.http_method, count.index)}"
  status_code = "${element(aws_api_gateway_method_response.Code200.*.status_code, count.index)}"
  #status_code = "200"
}

/* NOTE NOTE NOTE NOTE NOTE */

resource "aws_lambda_permission" "allow_api_gateway" {
  depends_on    = ["aws_api_gateway_integration.LambdaIntegration"]
  count         = "${length(var.dataStructure)}"
  function_name = "${aws_lambda_function.function.arn}"
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${var.accountId}:${aws_api_gateway_rest_api.RootAPI.id}/*/${upper(element(split(",", lookup(var.dataStructure[count.index], "api_gateway_method")), index(split(",", lookup(var.dataStructure[count.index], "api_gateway_target")), "lambda")))}/${element(split(",", lookup(var.dataStructure[count.index], "api_gateway_path")), index(split(",", lookup(var.dataStructure[count.index], "api_gateway_target")), "lambda"))}"
  qualifier     = "${aws_lambda_function.function.version}"
}

resource "aws_api_gateway_deployment" "DeployAPI" {
  depends_on  = ["aws_api_gateway_method.Method"]
  count       = "${length(var.dataStructure)}"
  rest_api_id = "${aws_api_gateway_rest_api.RootAPI.id}"
  # description = "Targets to ${aws_lambda_function.function.arn}:${aws_lambda_function.function.version}"
  stage_name  = "${lookup(var.dataStructure[count.index], "alias")}"
}
