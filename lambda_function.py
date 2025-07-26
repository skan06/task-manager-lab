# Import required Python libraries
import json
import boto3
import os
import uuid

# Initialize DynamoDB resource
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"]) # Get table name from environment variable

# Lambda handler function
def lambda_handler(event, context):
    # Extract path and HTTP method from the event
    path = event.get("rawPath", "")
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    
    # Handle POST /tasks to create a new task
    if method == "POST" and path == "/tasks":
        body = json.loads(event.get("body", "{}")) # Parse request body
        description = body.get("description") # Get task description
        if not description:
            return {"statusCode": 400, "body": json.dumps({"error": "Missing 'description' in request"})}
        task_id = str(uuid.uuid4()) # Generate unique task ID
        table.put_item(Item={"task_id": task_id, "description": description, "completed": False}) # Save to DynamoDB
        return {"statusCode": 200, "body": json.dumps({"task_id": task_id})}
    
    # Handle GET /tasks to list all tasks
    if method == "GET" and path == "/tasks":
        response = table.scan() # Scan DynamoDB table for all items
        return {"statusCode": 200, "body": json.dumps(response["Items"])}
    
    # Handle PUT /tasks/{task_id} to update a task
    if method == "PUT" and path.startswith("/tasks/"):
        task_id = path.split("/")[-1] # Extract task ID from path
        body = json.loads(event.get("body", "{}")) # Parse request body
        completed = body.get("completed", False) # Get completed status
        table.update_item( # Update task in DynamoDB
            Key={"task_id": task_id},
            UpdateExpression="SET completed = :c",
            ExpressionAttributeValues={":c": completed}
        )
        return {"statusCode": 200, "body": json.dumps({"message": "Task updated"})}
    
    # Handle DELETE /tasks/{task_id} to delete a task
    if method == "DELETE" and path.startswith("/tasks/"):
        task_id = path.split("/")[-1] # Extract task ID from path
        table.delete_item(Key={"task_id": task_id}) # Delete task from DynamoDB
        return {"statusCode": 200, "body": json.dumps({"message": "Task deleted"})}
    
    # Return 404 for unknown routes
    return {"statusCode": 404, "body": json.dumps({"error": "Route not found"})}