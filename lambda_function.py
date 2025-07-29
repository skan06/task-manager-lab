import json
import boto3
import os
import uuid

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'task-manager')  # Fallback to 'task-manager' if not set
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Handle API Gateway v2 HTTP API requests for task management.
    Supports POST, GET, PUT, DELETE methods for /tasks and /tasks/{task_id} routes.
    """
    try:
        # Log the incoming event for debugging
        print(f"Event: {json.dumps(event)}")
        
        # Extract httpMethod and path from API Gateway v2 event structure
        request_context = event.get('requestContext', {}).get('http', {})
        http_method = request_context.get('method')
        path = request_context.get('path', '')
        
        if http_method == 'POST' and path == '/tasks':
            body = json.loads(event.get('body', '{}'))
            description = body.get('description')
            if not description:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Missing description in request body'}),
                    'headers': {'Content-Type': 'application/json'}
                }
            task_id = str(uuid.uuid4())
            table.put_item(Item={'task_id': task_id, 'description': description})
            return {
                'statusCode': 200,
                'body': json.dumps({'task_id': task_id, 'description': description}),
                'headers': {'Content-Type': 'application/json'}
            }
        
        elif http_method == 'GET' and path == '/tasks':
            response = table.scan()
            items = response.get('Items', [])
            return {
                'statusCode': 200,
                'body': json.dumps(items),
                'headers': {'Content-Type': 'application/json'}
            }
        
        elif http_method == 'PUT' and path.startswith('/tasks/'):
            task_id = path.split('/')[-1]
            body = json.loads(event.get('body', '{}'))
            description = body.get('description')
            if not description:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Missing description in request body'}),
                    'headers': {'Content-Type': 'application/json'}
                }
            table.update_item(
                Key={'task_id': task_id},
                UpdateExpression='SET description = :desc',
                ExpressionAttributeValues={':desc': description}
            )
            return {
                'statusCode': 200,
                'body': json.dumps({'task_id': task_id, 'description': description}),
                'headers': {'Content-Type': 'application/json'}
            }
        
        elif http_method == 'DELETE' and path.startswith('/tasks/'):
            task_id = path.split('/')[-1]
            table.delete_item(Key={'task_id': task_id})
            return {
                'statusCode': 200,
                'body': json.dumps({'message': f'Task {task_id} deleted'}),
                'headers': {'Content-Type': 'application/json'}
            }
        
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': f'Unsupported method {http_method} or path {path}'}),
                'headers': {'Content-Type': 'application/json'}
            }
            
    except Exception as e:
        # Log the error for CloudWatch
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal Server Error', 'error': str(e)}),
            'headers': {'Content-Type': 'application/json'}
        }