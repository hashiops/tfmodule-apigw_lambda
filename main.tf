module "lambda-default-iam" {
  source = "../lambda-default-iam"
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

resource "aws_api_gateway_rest_api" "RootAPI" {
  name        = "API NAME" # "${var.api_gateway_name}"
  description = "api description" # "${var.api_gateway_description}"
  body        = <<EOF
  swagger: '2.0'
  info:
    title: "API NAME"
    version: "0.1"
    description: "api description"
  schemes:
  - https
  - http
  paths:
    "/api":
      post:
        consumes:
        - application/json
        produces:
        - application/json
        parameters:
        - name: InvocationType
          in: header
          required: false
          type: string
        - in: body
          name: Input
          required: true
          schema:
            "$ref": "#/definitions/Input"
        responses:
          '200':
            description: 200 response
            schema:
              "$ref": "#/definitions/Result"
        x-amazon-apigateway-request-validator: Validate body
        x-amazon-apigateway-integration:
          responses:
            default:
              statusCode: '200'
              responseTemplates:
                application/json: ""
          uri: arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:261490016054:function:python_Function:hash_0/invocations
          passthroughBehavior: when_no_templates
          httpMethod: POST
          type: aws
  definitions:
    Input:
      type: object
      required:
      - a
      properties:
        a:
          type: number
      title: Input
    Output:
      type: object
      properties:
        c:
          type: number
      title: Output
    Result:
      type: object
      properties:
        input:
          "$ref": "#/definitions/Input"
        output:
          "$ref": "#/definitions/Output"
      title: Result
  x-amazon-apigateway-request-validators:
    Validate body:
      validateRequestParameters: false
      validateRequestBody: true
    Validate query string parameters and headers:
      validateRequestParameters: true
      validateRequestBody: false
EOF
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
