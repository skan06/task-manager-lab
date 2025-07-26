# Generate a random suffix for unique bucket naming
resource "random_id" "suffix" {
  byte_length = 4 # 4 bytes for a unique hex string
}

# Create an S3 bucket for hosting the frontend
resource "aws_s3_bucket" "frontend_ui" {
  bucket = "task-manager-frontend-${random_id.suffix.hex}" # Unique bucket name
  force_destroy = true # Allow bucket deletion even if not empty (for testing)
}

# Enable static website hosting on the S3 bucket
resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend_ui.id # Link to the S3 bucket
  index_document {
    suffix = "index.html" # Default file served
  }
}

# Configure public access settings for the S3 bucket
resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket = aws_s3_bucket.frontend_ui.id      # Link to the S3 bucket
  block_public_acls       = true            # Block public ACLs
  block_public_policy     = false           # Allow public bucket policies
  ignore_public_acls      = true            # Ignore public ACLs
  restrict_public_buckets = false           # Allow public bucket policies
}

# Set a bucket policy to allow public read access
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_ui.id # Link to the S3 bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = "*",                      # Allow all principals (public access)
      Action = ["s3:GetObject"],            # Allow reading objects
      Resource = "${aws_s3_bucket.frontend_ui.arn}/*" # Apply to all objects in the bucket
    }]
  })
}

# Upload the index.html file with the API endpoint injected
resource "aws_s3_object" "frontend_index" {
  bucket       = aws_s3_bucket.frontend_ui.id
  key          = "index.html"
  content      = templatefile("${path.module}/../../frontend/index.html", { apiEndpoint = var.api_endpoint })
  content_type = "text/html"
}

# Upload the style.css file
resource "aws_s3_object" "frontend_css" {
  bucket       = aws_s3_bucket.frontend_ui.id  # Link to the S3 bucket
  key          = "style.css"                 # Object key in S3
  source       = "${path.module}/../../frontend/style.css" # Local path to CSS file
  content_type = "text/css"                  # MIME type for CSS
}