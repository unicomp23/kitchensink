import boto3
import os
import pandas as pd
import json
import urllib.parse

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table_name = os.environ['DYNAMODB_TABLE']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    bucket_name = os.environ['BUCKET_NAME']

    # Construct folder_name and remove trailing slash
    key = event['Records'][0]['s3']['object']['key']
    folder_name = "/".join(key.split("/")[:-1])
    folder_name = urllib.parse.unquote(folder_name).rstrip('/')
    print(f"Decoded folder_name: '{folder_name}'")

    # Query DynamoDB
    response = table.get_item(Key={"folder_name": folder_name})
    if "Item" not in response:
        print(f"No record found for folder {folder_name}. Skipping.")
        return {"statusCode": 400, "body": "Folder not tracked in DynamoDB."}

    record = response["Item"]
    expected_count = int(record["expected_count"])
    uploaded_count = int(record["uploaded_count"])

    # Atomic increment of uploaded_count with thread safety
    try:
        dynamo_response = table.update_item(
            Key={"folder_name": folder_name},
            UpdateExpression="SET uploaded_count = uploaded_count + :inc",
            ConditionExpression="uploaded_count < :expected_count",
            ExpressionAttributeValues={
                ":inc": 1,
                ":expected_count": expected_count
            },
            ReturnValues="UPDATED_NEW"
        )
        uploaded_count = int(dynamo_response["Attributes"]["uploaded_count"])
        print(f"Uploaded count updated to {uploaded_count}/{expected_count}")
    except dynamodb.meta.client.exceptions.ConditionalCheckFailedException:
        print(f"Uploaded count already reached expected count for folder {folder_name}. Skipping increment.")
        return {"statusCode": 200, "body": "Duplicate or extra event ignored."}

    # Check if all files are uploaded
    if uploaded_count == expected_count:
        print(f"All files uploaded for {folder_name}. Processing...")
        process_folder(bucket_name, folder_name)
        table.update_item(
            Key={"folder_name": folder_name},
            UpdateExpression="SET is_processed = :true",
            ExpressionAttributeValues={":true": True}
        )
    else:
        print(f"Waiting for more files. Uploaded: {uploaded_count}, Expected: {expected_count}")

    return {"statusCode": 200, "body": "File upload tracked successfully."}

def process_folder(bucket_name, folder_name):
    print(f"Processing folder: {folder_name}")

    # List all files in the folder
    response = s3.list_objects_v2(Bucket=bucket_name, Prefix=folder_name)
    if "Contents" not in response:
        print(f"No files found in folder {folder_name}. Skipping.")
        return

    # Combine files into one log file
    combined_file_path = "/tmp/consumer.log"
    with open(combined_file_path, 'w') as outfile:
        for obj in response['Contents']:
            file_key = obj['Key']
            if file_key.endswith('/'):
                continue  # Skip folder key
            obj_data = s3.get_object(Bucket=bucket_name, Key=file_key)['Body'].read().decode('utf-8')
            outfile.write(obj_data + '\n')

    # Upload combined file to the perm folder
    perm_folder = folder_name.replace("consumer-logs-temp", "consumer-logs-perm")
    combined_key = f"{perm_folder}/consumer.log"
    s3.upload_file(combined_file_path, bucket_name, combined_key)

    # Perform analytics and upload results
    try:
        data = pd.read_csv(combined_file_path, low_memory=False)
        data['Latency'] = pd.to_numeric(data['Latency'], errors='coerce')  # Convert to numeric, set invalid to NaN
        data.dropna(subset=['Latency'], inplace=True)  # Drop rows with NaN values in the Latency column

        results = {
            'average_latency': data['Latency'].mean(),
            'median_latency': data['Latency'].median(),
            'percentile_99.99': data['Latency'].quantile(0.9999),
            'messages_meeting_kpi': data[data['KPI'] == 'meets KPI'].shape[0],
            'messages_not_meeting_kpi': data[data['KPI'] != 'meets KPI'].shape[0],
            'top_5_highest_latency': data.nlargest(5, 'Latency').to_dict(orient='records')
        }

        analytics_file_path = "/tmp/consumer.json"
        with open(analytics_file_path, 'w') as json_file:
            json.dump(results, json_file, indent=4)

        analytics_key = f"{perm_folder}/consumer.json"
        s3.upload_file(analytics_file_path, bucket_name, analytics_key)
        print(f"Analytics report uploaded to {analytics_key}")
    except Exception as e:
        print(f"Error during analytics processing: {e}")
        raise e
