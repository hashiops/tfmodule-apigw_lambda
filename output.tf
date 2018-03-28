output "lambda_function_id" {
  value = "${aws_lambda_function.function.id}"
}

output "apigw_id" {
  value = "${aws_api_gateway_rest_api.RootAPI.id}"
}
