import boto3
import json
import os

def lambda_handler(event, context):

    records = event['Records']
    s3_record = records[0]['body']
    s3_event = json.loads(s3_record)['Message']
    input_bucket_name = json.loads(s3_event)['Records'][0]['s3']['bucket']['name']
    input_file_name = json.loads(s3_event)['Records'][0]['s3']['object']['key']
    
    stepfunctions_client = boto3.client('stepfunctions')
    
    stepfunction_arn = os.environ['stepfunction_arn']
    
    response = stepfunctions_client.start_execution(
        stateMachineArn=stepfunction_arn,
        input=json.dumps({'input_file_name': input_file_name, 'input_bucket_name': input_bucket_name})
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('StepFunction started!')
    }