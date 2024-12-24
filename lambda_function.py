# lambda_function.py

import boto3
from datetime import datetime, timedelta

def lambda_handler(event, context):
    ce_client = boto3.client('ce')
    sns_client = boto3.client('sns')
    
    end_date = datetime.now()
    start_date = end_date - timedelta(days=30)

    try:
        # Fetch the cost data from AWS Cost Explorer
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='DAILY',
            Metrics=['UnblendedCost']
        )
        
        print("Daily cost data:", response)

        # Check if the cost exceeds the threshold
        total_cost = sum([day['Total']['UnblendedCost']['Amount'] for day in response['ResultsByTime']])
        
        if total_cost > float(os.environ['COST_THRESHOLD']):
            sns_client.publish(
                TopicArn=os.environ['SNS_TOPIC_ARN'],
                Message=f"Cost has exceeded the threshold. Total cost: ${total_cost}",
                Subject="AWS Cost Alert"
            )

    except Exception as e:
        print(f"Error retrieving cost data: {e}")
