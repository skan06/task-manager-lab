# Create an S3 bucket for hosting the frontend
resource "aws_s3_bucket" "frontend_ui" {
  bucket        = "task-manager-frontend-${var.suffix}" # Unique bucket name using suffix
  force_destroy = true                                 # Allow bucket deletion even if non-empty
}

# Enable versioning on the S3 bucket to allow recovery
resource "aws_s3_bucket_versioning" "frontend_versioning" {
  bucket = aws_s3_bucket.frontend_ui.id
  versioning_configuration {
    status = "Enabled" # Required for Terrascan compliance
  }
}

# Enable static website hosting on the S3 bucket
resource "aws_s3_bucket_website_configuration" "frontend_config" {
  bucket = aws_s3_bucket.frontend_ui.id
  index_document {
    suffix = "index.html" # Default file for website
  }
}

# Configure public access settings for the S3 bucket
resource "aws_s3_bucket_public_access_block" "frontend_public_access" {
  bucket                  = aws_s3_bucket.frontend_ui.id
  block_public_acls       = false # Allow public ACLs
  block_public_policy     = false # Allow public policies
  ignore_public_acls      = false # Consider public ACLs
  restrict_public_buckets = false # Allow public bucket access
}

# Set a bucket policy to allow public read access
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_ui.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"                                 # Allow public access
      Action    = ["s3:GetObject"]                    # Permit reading objects
      Resource  = "${aws_s3_bucket.frontend_ui.arn}/*" # Apply to all objects
    }]
  })
  depends_on = [aws_s3_bucket_public_access_block.frontend_public_access] # Ensure access block is applied
}

# Upload the index.html file with the API endpoint injected
resource "aws_s3_object" "frontend_index" {
  bucket       = aws_s3_bucket.frontend_ui.id
  key          = "index.html"                    # Object key
  content      = templatefile("${path.module}/../../frontend/index.html", { apiEndpoint = var.api_endpoint })
  content_type = "text/html"                     # MIME type
}

# Upload the style.css file
resource "aws_s3_object" "frontend_css" {
  bucket       = aws_s3_bucket.frontend_ui.id
  key          = "style.css"
  source       = "${path.module}/../../frontend/style.css" # Path to CSS file
  content_type = "text/css"
}