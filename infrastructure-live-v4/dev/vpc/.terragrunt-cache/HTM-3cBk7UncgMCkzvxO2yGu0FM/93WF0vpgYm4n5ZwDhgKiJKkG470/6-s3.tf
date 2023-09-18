

resource "aws_s3_bucket" "thanos_bucket" {
  bucket = var.thanos_bucket # Change this to a unique name
  acl    = "private"          # Set to "private" to ensure your bucket contents aren't publicly accessible

  versioning {
    enabled = true
  }

  # Add lifecycle rules if desired. The example below transitions objects to the "GLACIER" storage class after 90 days.
  # And objects are expired (deleted) after 365 days.
  lifecycle_rule {
    id      = "log"
    enabled = true

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }


  tags = {
    Environment = var.env
    Application = "thanos"
  }
}
