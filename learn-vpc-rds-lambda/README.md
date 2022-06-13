https://docs.aws.amazon.com/lambda/latest/dg/services-rds-tutorial.html

In this tutorial, you do the following:

1. Launch an Amazon RDS MySQL database engine instance in your default Amazon VPC. In the MySQL instance, you create a database (ExampleDB) with a sample table (Employee) in it. For more information about Amazon RDS, see [Amazon RDS](https://aws.amazon.com/rds/).

2. Create a Lambda function to access the ExampleDB database, create a table (Employee), add a few records, and retrieve the records from the table.

3. Invoke the Lambda function and verify the query results. This is how you verify that your Lambda function was able to access the RDS MySQL instance in the VPC.

For details on using Lambda with Amazon VPC, see [Configuring a Lambda function to access resources in a VPC](https://docs.aws.amazon.com/lambda/latest/dg/services-rds-tutorial.html)


Executing pymysql.connect() outside of the handler allows your function to re-use the database connection for better performance.


You can launch an RDS MySQL instance using one of the following methods:

Follow the instructions at Creating a MySQL DB instance and connecting to a database on a MySQL DB instance in the Amazon RDS User Guide.

Use the following AWS CLI command:
``` bash
aws rds create-db-instance --db-name ExampleDB --engine MySQL \
--db-instance-identifier MySQLForLambdaTest --backup-retention-period 3 \
--db-instance-class db.t2.micro --allocated-storage 5 --no-publicly-accessible \
--master-username username --master-user-password password
```

"DBInstance": {
        "DBInstanceIdentifier": "mysqlforlambdatest",
        "DBInstanceClass": "db.t2.micro",
        "Engine": "mysql",
        "DBInstanceStatus": "creating",
        "MasterUsername": "username",
        "DBName": "ExampleDB",
        "AllocatedStorage": 5,
        "PreferredBackupWindow": "10:26-10:56",
        "BackupRetentionPeriod": 3,
        "DBSecurityGroups": [],
        "VpcSecurityGroups": [
            {
                "VpcSecurityGroupId": "sg-0be42d1aa12bc29a6",
                "Status": "active"


                "DBInstance": {
        "DBInstanceIdentifier": "mysqlforlambdatest",
        "DBInstanceClass": "db.t2.micro",
        "Engine": "mysql",
        "DBInstanceStatus": "creating",
        "MasterUsername": "username",
        "DBName": "ExampleDB",
        "AllocatedStorage": 5,
        "PreferredBackupWindow": "10:26-10:56",
        "BackupRetentionPeriod": 3,
        "DBSecurityGroups": [],
        "VpcSecurityGroups": [
            {
                "VpcSecurityGroupId": "sg-0be42d1aa12bc29a6",
                "Status": "active"
            }

              "DBParameterGroups": [
            {
                "DBParameterGroupName": "default.mysql8.0",
                "ParameterApplyStatus": "in-sync"
            }
        ],
        "DBSubnetGroup": {
            "DBSubnetGroupName": "default",
            "DBSubnetGroupDescription": "default",
            "VpcId": "vpc-0ac2df1762e4b854e",
            "SubnetGroupStatus": "Complete",
            "Subnets": [
                {
                    "SubnetIdentifier": "subnet-0f644c052c9d2c0c2",
                    "SubnetAvailabilityZone": {
                        "Name": "us-east-1a"
                    },
                    "SubnetOutpost": {},
                    "SubnetStatus": "Active"



aws lambda create-function --function-name  CreateTableAddRecordsAndRead --runtime python3.8 \
--zip-file fileb://package/package.zip --handler app.handler \
--role arn:aws:iam::624164837375:role/lambda-vpc-role \
--vpc-config SubnetIds=subnet-0f644c052c9d2c0c2,subnet-0308ae0e08c12a924,SecurityGroupIds=sg-0be42d1aa12bc29a6
{
    "FunctionName": "CreateTableAddRecordsAndRead",
    "FunctionArn": "arn:aws:lambda:us-east-1:624164837375:function:CreateTableAddRecordsAndRead",
    "Runtime": "python3.8",
    "Role": "arn:aws:iam::624164837375:role/lambda-vpc-role",
    "Handler": "app.handler",
    "CodeSize": 1803972,
    "Description": "",
    "Timeout": 3,
    "MemorySize": 128,
    "LastModified": "2021-07-28T23:05:36.277+0000",
    "CodeSha256": "2K/EV3G12/i+L3Qwv94TjMbktulR4Nr1qngA5JASnc0=",
    "Version": "$LATEST",
    "VpcConfig": {
        "SubnetIds": [
            "subnet-0308ae0e08c12a924",
            "subnet-0f644c052c9d2c0c2"
        ],
        "SecurityGroupIds": [
            "sg-0be42d1aa12bc29a6"
        ],
        "VpcId": "vpc-0ac2df1762e4b854e"
    },
    "TracingConfig": {
        "Mode": "PassThrough"
   


aws lambda invoke --function-name CreateTableAddRecordsAndRead output.txt

{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}

