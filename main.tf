/* TODO Add variables for support of swagger template of API */

module "lambda-default-iam" {
  source = "github.com/hashiops/tfmodule-lambda_default_iam"

  environment = "${var.environment}"
  application_name = "${lookup(var.dataStructure,"lambda_function_name")}"
}

resource "aws_lambda_function" "function" {
#  count             = "${lookup(var.dataStructure,"lambda_vpc") ? 1 : 0}"
  function_name     = "${var.environment}-${lookup(var.dataStructure,"lambda_function_name")}"
  role              = "${module.lambda-default-iam.lambda_role_arn}"
  handler           = "${lookup(var.dataStructure,"lambda_function_handler")}"
  runtime           = "${lookup(var.dataStructure,"lambda_function_runtime")}"
  timeout           = "${lookup(var.dataStructure,"lambda_function_timeout")}"
  memory_size       = "${lookup(var.dataStructure,"lambda_function_memory")}"
  filename          = "source.zip"

  environment {
    variables = {
      databaseConfigurationRegion = "${var.region}"
      databaseConfigurationUrl = "${lookup(var.dataStructure,"lambda_db_url")}"
      env = "${lookup(var.dataStructure,"environment")}"
    }
  }

  vpc_config {
       subnet_ids = ["${split(",", lookup(var.dataStructure,"lambda_subnet_ids"))}"]
       security_group_ids = ["${split(",", lookup(var.dataStructure,"lambda_security_group_ids"))}"]
   }

  lifecycle = {
    ignore_changes = ["filename"]
  }
}

# resource "aws_lambda_function" "function" {
#   count             = "${lookup(var.dataStructure,"lambda_vpc") ? 0 : 1}"
#   function_name     = "${var.environment}-${lookup(var.dataStructure,"lambda_function_name")}"
#   role              = "${module.lambda-default-iam.lambda_role_arn}"
#   handler           = "${lookup(var.dataStructure,"lambda_function_handler")}"
#   runtime           = "${lookup(var.dataStructure,"lambda_function_runtime")}"
#   timeout           = "${lookup(var.dataStructure,"lambda_function_timeout")}"
#   memory_size       = "${lookup(var.dataStructure,"lambda_function_memory")}"
#   filename          = "source.zip"
#
#   environment {
#     variables = {
#       databaseConfigurationRegion = "${var.region}"
#       databaseConfigurationUrl = "${lookup(var.dataStructure,"lambda_db_url")}"
#       env = "${lookup(var.dataStructure,"environment")}"
#     }
#   }
#
#   lifecycle = {
#     ignore_changes = ["filename"]
#   }
# }

resource "aws_api_gateway_rest_api" "RootAPI" {
  name        = "${upper(var.environment)}-${lookup(var.dataStructure,"api_gateway_name")}"
  description = "${lookup(var.dataStructure,"api_gateway_description")}"
}

# resource "null_resource" "RootAPI_configuration" {
#
#   triggers {
#     endpoint_configuration_type = "${aws_api_gateway_rest_api.RootAPI.id}"
#   }
#   provisioner "local-exec" {
#     command = "aws apigateway update-rest-api --rest-api-id ${aws_api_gateway_rest_api.RootAPI.id} --patch-operations op=replace,path=/endpointConfiguration/types/EDGE,value=REGIONAL"
#   }
# }

resource "aws_api_gateway_domain_name" "RootAPI" {
  domain_name = "${var.environment}-${lookup(var.dataStructure,"lambda_function_name")}.${var.root_domain}"

  certificate_arn  = "${lookup(var.dataStructure,"api_gateway_acm_cert")}"
}

resource "aws_api_gateway_base_path_mapping" "RootAPI" {
  api_id      = "${aws_api_gateway_rest_api.RootAPI.id}"
  domain_name = "${aws_api_gateway_domain_name.RootAPI.domain_name}"
}

resource "aws_route53_record" "RootAPI" {
  zone_id = "${var.route53_zone_id}"

  name = "${aws_api_gateway_domain_name.RootAPI.domain_name}"
  type = "A"

  alias {
    name                   = "${aws_api_gateway_domain_name.RootAPI.cloudfront_domain_name}"
    zone_id                = "${aws_api_gateway_domain_name.RootAPI.cloudfront_zone_id}"
    evaluate_target_health = true
  }
}
