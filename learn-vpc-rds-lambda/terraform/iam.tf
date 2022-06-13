Create the execution role
Create the execution role that gives your function permission to access AWS resources.

To create an execution role

Open the roles page in the IAM console.

Choose Create role.

Create a role with the following properties.

Trusted entity – Lambda.

Permissions – AWSLambdaVPCAccessExecutionRole.

Role name – lambda-vpc-role.

The AWSLambdaVPCAccessExecutionRole has the permissions that the function needs to manage network connections to a VPC.