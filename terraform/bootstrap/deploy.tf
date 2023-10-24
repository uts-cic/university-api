provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_s3_bucket" "tf_university_api" {
  bucket = "utscic-tf-university-api"
}

resource "aws_s3_bucket_versioning" "tf_university_api" {
  bucket = aws_s3_bucket.tf_university_api.id

  versioning_configuration {
    status = "Enabled"
  }
}
