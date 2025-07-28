# Generate a random suffix for unique bucket naming
resource "random_id" "suffix" {
  byte_length = 4 # Creates an 8-character hex string for uniqueness
}

# Create an S3 bucket for hosting the frontend
resource "aws_s3_bucket" "frontend_ui" {
  bucket        = "task-manager-frontend-${random_id.suffix.hex}" # Unique bucket name
  force_destroy = true # Allows bucket deletion even if non-empty during cleanup
}

# Enable static website hosting on the S3 bucket
resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend_ui.id # References the S3 bucket
  index_document {
    suffix = "index.html" # Default file served for website
  }
}

# Configure public access settings for the S3 bucket
resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket                  = aws_s3_bucket.frontend_ui.id # References the S3 bucket
  block_public_acls       = false # Allows public ACLs
  block_public_policy     = false # Allows public bucket policies
  ignore_public_acls      = false # Considers public ACLs
  restrict_public_buckets = false # Allows public bucket access
}

# Set a bucket policy to allow public read access
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_ui.id # References the S3 bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*" # Allows public access
      Action    = ["s3:GetObject"] # Permits reading objects
      Resource  = "${aws_s3_bucket.frontend_ui.arn}/*" # Applies to all objects in bucket
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.frontend_public_access] # Ensures public access block is applied first
}

# Upload the index.html file with the API endpoint injected
resource "aws_s3_object" "frontend_index" {
  bucket       = aws_s3_bucket.frontend_ui.id # References the S3 bucket
  key          = "index.html" # Object key in S3
  content      = templatefile("${path.module}/../../frontend/index.html", { apiEndpoint = var.api_endpoint }) # Injects API endpoint
  content_type = "text/html" # MIME type for HTML
}

# Upload the style.css file
resource "aws_s3_object" "frontend_css" {
  bucket       = aws_s3_bucket.frontend_ui.id # References the S3 bucket
  key          = "style.css" # Object key in S3
  source       = "${path.module}/../../frontend/style.css" # Path to local CSS file
  content_type = "text/css" # MIME type for CSS
}
