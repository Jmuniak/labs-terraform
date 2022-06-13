terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.48.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }

  required_version = "~> 1.0"
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "lambda_bucket_name" {
  prefix = "learn-terraform-functions"
  length = 4
}

resource "aws_s3_bucket" "lambda_bucket" {
  bucket = random_pet.lambda_bucket_name.id

  acl           = "private"
  force_destroy = true
}
### END OF STARTING POINT FOR S3 bucket


## CODE added to package and copy hello-world lambda function to the s3 bucket.
### This configuration uses the archive_file data source to generate a zip archive 
#### and an aws_s3_bucket_object resource to upload the archive to your S3 bucket.
data "archive_file" "lambda_hello_world" {
  type = "zip"
  
  source_dir = "${path.module}/hello-world"
  output_path = "${path.module}/hello-world.zip"
}
resource "aws_s3_bucket_object" "lambda_hello_world" {
  bucket = aws_s3_bucket.lambda_bucket.id

  key = "hello-world.zip"
  source = data.archive_file.lambda_hello_world.output_path

  etag = filemd5(data.archive_file.lambda_hello_world.output_path)
}
## Once Terraform deploys your function to S3, use the AWS CLI to inspect the contents of the S3 bucket.
## $ aws s3 ls $(terraform output -raw lambda_bucket_name)
## 2021-07-08 13:49:46        353 hello-world.zip

#### END OF LAMBDA ZIP OBJECT FOR S3



###### Create the Lambda function  #########
## This configuration defines four resources:

##### 1. aws_lambda_function.hello_world configures the Lambda function to use the bucket object containing your function code. 
## It also sets the runtime to NodeJS 12.x, and assigns the handler to the handler function defined in hello.js. 
## The source_code_hash attribute will change whenever you update the code contained in the archive, 
## which lets Lambda know that there is a new version of your code available. 
## Finally, the resource specifies a role which grants the function permission to access AWS services and resources in your account.
resource "aws_lambda_function" "hello_world" {
  function_name = "HelloWorld"

  s3_bucket = aws_s3_bucket.lambda_bucket.id
  s3_key    = aws_s3_bucket_object.lambda_hello_world.key

  runtime = "nodejs12.x"
  handler = "hello.handler"

  source_code_hash = data.archive_file.lambda_hello_world.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}
##### 2. aws_cloudwatch_log_group.hello_world defines a log group to store log messages from your Lambda function for 30 days. 
## By convention, Lambda stores logs in a group with the name /aws/lambda/<Function Name>.
resource "aws_cloudwatch_log_group" "hello_world" {
  name = "/aws/lambda/${aws_lambda_function.hello_world.function_name}"

  retention_in_days = 30
}
##### 3. aws_iam_role.lambda_exec defines an IAM role that allows Lambda to access resources in your AWS account.
resource "aws_iam_role" "lambda_exec" {
  name = "serverless_lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}
##### 4. aws_iam_role_policy_attachment.lambda_policy attaches a policy the IAM role.
## The AWSLambdaBasicExecutionRole is an AWS managed policy that allows your Lambda function to write to CloudWatch logs.
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

## Once Terraform creates the function, invoke it using the AWS CLI.

### $ aws lambda invoke --region=us-east-1 --function-name=$(terraform output -raw function_name) response.json
### {
###    "StatusCode": 200,
###    "ExecutedVersion": "$LATEST"
### }

### $ cat response.json
#### END OF LAMBDA FUNCTION AND ASSOCIATED IAM ROLES


###### Create an HTTP API with API Gateway #########
### This configuration defines four API Gateway resources, and two supplemental resources:
### 1. aws_apigatewayv2_api.lambda defines a name for the API Gateway and sets its protocol to HTTP.
resource "aws_apigatewayv2_api" "lambda" {
  name          = "serverless_lambda_gw"
  protocol_type = "HTTP"
}

### 2. aws_apigatewayv2_stage.lambda sets up application stages for the API Gateway - such as "Test", 
#### Staging", and "Production". The example configuration defines a single stage, with access logging enabled.
resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}
### 3. aws_apigatewayv2_integration.hello_world configures the API Gateway to use your Lambda function.
resource "aws_apigatewayv2_integration" "hello_world" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = aws_lambda_function.hello_world.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}
### 4. aws_apigatewayv2_route.hello_world maps an HTTP request to a target, in this case your Lambda function.
#### In the example configuration, the route_key matches any GET request matching the path /hello. 
#### A target matching integrations/<ID> maps to a Lambda integration with the given ID.
resource "aws_apigatewayv2_route" "hello_world" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "GET /hello"
  target    = "integrations/${aws_apigatewayv2_integration.hello_world.id}"
}

### 5. aws_cloudwatch_log_group.api_gw defines a log group to store access logs for the aws_apigatewayv2_stage.lambda API Gateway stage.
resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"
  retention_in_days = 30
}

### 6. aws_lambda_permission.api_gw gives API Gateway permission to invoke your Lambda function.
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}
## The API Gateway stage will publish your API to a URL managed by AWS.
## apply changes

## Now, send a request to API Gateway to invoke the Lambda function. 
## The endpoint consists of the base_url output value and the /hello path, which do you defined as the route_key.
## $ curl "$(terraform output -raw base_url)/hello"
## {"message":"Hello, World!"} 

# resource "aws_apigatewayv2_deployment" "example" {
#   api_id      = aws_apigatewayv2_route.hello_world.api_id
#   description = "API hello_world deployment"

#   lifecycle {
#     create_before_destroy = true
#   }
# }
#### END OF API GW



###### update the Lambda function  #########
# When you call Lambda functions via API Gateway's proxy integration, 
# API Gateway passes the request information to your function via the event object. 
# You can use information about the request in your function code.

# Now, use an HTTP query parameter in your function.

# In hello-world/hello.js, add an if statement to replace the responseMessage if the request includes a Name query parameter.

# hello-world/hello.js
#  module.exports.handler = async (event) => {
#    console.log('Event: ', event)
#    let responseMessage = 'Hello, World!';

# +  if (event.queryStringParameters && event.queryStringParameters['Name']) {
# +    responseMessage = 'Hello, ' + event.queryStringParameters['Name'] + '!';
# +  }
# +
#    return {
#      statusCode: 200,
#      headers: {
#        'Content-Type': 'application/json',
#      },
#      body: JSON.stringify({
#        message: responseMessage,
#      }),
#    }
#  }
## Apply this change now. Since your source code changed, the computed etag and source_code_hash values have changed as well. 
## Terraform will update your S3 bucket object and Lambda function.

## Now, send another request to your function, including the Name query parameter.
## $ curl "$(terraform output -raw base_url)/hello?Name=Terraform"