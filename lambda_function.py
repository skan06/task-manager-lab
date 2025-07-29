import json
import boto3
import os
import uuid

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('TABLE_NAME', 'task-manager')  # Fallback to 'task-manager' if TABLE_NAME env var is not set
table = dynamodb.Table(table_name)                        # Reference to the DynamoDB table

def lambda_handler(event, context):
    """
    Handle API Gateway v2 HTTP API requests for task management.
    Supports POST, GET, PUT, DELETE methods for /tasks and /tasks/{task_id} routes.
    """
    try:
        # Log the incoming event for debugging in CloudWatch
        print(f"Event: {json.dumps(event)}")
        
        # Extract httpMethod and path from API Gateway v2 event structure
        request_context = event.get('requestContext', {}).get('http', {})
        http_method = request_context.get('method')           # HTTP method (POST, GET, etc.)
        path = request_context.get('path', '')                # Request path (/tasks or /tasks/{task_id})
        
        # Handle POST /tasks: Create a new task
        if http_method == 'POST' and path == '/tasks':
            body = json.loads(event.get('body', '{}'))        # Parse request body
            description = body.get('description')             # Extract description
            if not description:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Missing description in request body'}),
                    'headers': {'Content-Type': 'application/json'}
                }
            task_id = str(uuid.uuid4())                       # Generate unique task ID
            table.put_item(Item={'task_id': task_id, 'description': description})  # Save to DynamoDB
            return {
                'statusCode': 200,
                'body': json.dumps({'task_id': task_id, 'description': description}),
                'headers': {'Content-Type': 'application/json'}
            }
        
        # Handle GET /tasks: List all tasks
        elif http_method == 'GET' and path == '/tasks':
            response = table.scan()                           # Scan DynamoDB table
            items = response.get('Items', [])                 # Extract items (list of tasks)
            return {
                'statusCode': 200,
                'body': json.dumps(items),                    # Return items directly as array
                'headers': {'Content-Type': 'application/json'}
            }
        
        # Handle PUT /tasks/{task_id}: Update a task
        elif http_method == 'PUT' and path.startswith('/tasks/'):
            task_id = path.split('/')[-1]                     # Extract task_id from path
            body = json.loads(event.get('body', '{}'))        # Parse request body
            description = body.get('description')             # Extract description
            if not description:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Missing description in request body'}),
                    'headers': {'Content-Type': 'application/json'}
                }
            table.update_item(
                Key={'task_id': task_id},                     # Key to identify task
                UpdateExpression='SET description = :desc',   # Update description
                ExpressionAttributeValues={':desc': description}
            )
            return {
                'statusCode': 200,
                'body': json.dumps({'task_id': task_id, 'description': description}),
                'headers': {'Content-Type': 'application/json'}
            }
        
        # Handle DELETE /tasks/{task_id}: Delete a task
        elif http_method == 'DELETE' and path.startswith('/tasks/'):
            task_id = path.split('/')[-1]                     # Extract task_id from path
            table.delete_item(Key={'task_id': task_id})       # Delete from DynamoDB
            return {
                'statusCode': 200,
                'body': json.dumps({'message': f'Task {task_id} deleted'}),
                'headers': {'Content-Type': 'application/json'}
            }
        
        # Handle unsupported methods or paths
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': f'Unsupported method {http_method} or path {path}'}),
                'headers': {'Content-Type': 'application/json'}
            }
            
    # Catch and log any errors
    except Exception as e:
        print(f"Error: {str(e)}")                            # Log error to CloudWatch
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal Server Error', 'error': str(e)}),
            'headers': {'Content-Type': 'application/json'}
        }