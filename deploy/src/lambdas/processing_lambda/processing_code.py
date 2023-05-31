import boto3
import os
import awswrangler as wr
import pandas as pd

def lambda_handler(event, context):

    s3 = boto3.client('s3')

    # Reading S3 buckets names and file key name
    input_bucket_name = event['input_bucket_name']
    input_file_name = event['input_file_name']
    output_bucket_name = os.environ['output_bucket_name']
    output_file_key = 'processed_data.csv'
    
    # Reading the file key
    s3_url = f"s3://{input_bucket_name}/{input_file_name}"
    df = wr.s3.read_csv(s3_url)
    #df = pd.read_csv(s3_url)

    # Processing Data
    columns = ["Invoice ID", "Date", "City", "Product line", "Unit price", "Quantity", "Total"]
    today_data = df[columns]

    # Trying to read the data from previous days
    try:
        older_data = wr.s3.read_csv(f"s3://{output_bucket_name}/data/{output_file_key}")
        print("Older data read.")

        # Deleting older files from the output bucket
        wr.s3.delete_objects(f"s3://{output_bucket_name}/")

        # Concatenating previous data with current day data        
        today_data = pd.concat([today_data, older_data]).drop_duplicates(inplace=True)
    except:
        print("There's no older data.")
        pass

    # Saving the updated data into S3 Output bucket
    wr.s3.to_csv(today_data, f"s3://{output_bucket_name}/data/{output_file_key}", index=False)

    return "Success!"
