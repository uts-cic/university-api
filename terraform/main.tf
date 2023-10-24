provider "aws" {
  region = "ap-southeast-2"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.22.0"
    }
  }

  backend "s3" {
    bucket  = "utscic-tf-university-api"
    key     = "terraform.tfstate"
    region  = "ap-southeast-2"
    encrypt = true
  }
}

resource "aws_s3_bucket" "university_api_bucket" {
  bucket = "university-api"

  tags = {
    Name = "University API"
  }
}

resource "aws_s3_bucket_ownership_controls" "university_api_bucket" {
  bucket = aws_s3_bucket.university_api_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "university_api_bucket" {
  depends_on = [aws_s3_bucket_ownership_controls.university_api_bucket]

  bucket = aws_s3_bucket.university_api_bucket.id
  acl    = "private"
}


resource "aws_s3_bucket_policy" "university_api_policy" {
  bucket = aws_s3_bucket.university_api_bucket.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowCloudFrontAccess",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.university_api_oai.id}"
        },
        "Action" : "s3:GetObject",
        "Resource" : "${aws_s3_bucket.university_api_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_identity" "university_api_oai" {
  comment = "University API OAI"
}

resource "aws_cloudfront_distribution" "university_api_cloudfront" {
  enabled = true
  aliases = ["university-api.utscic.edu.au"]

  origin {
    domain_name = aws_s3_bucket.university_api_bucket.bucket_regional_domain_name
    origin_id   = "S3-university-api"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.university_api_oai.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = "canvas.uts.edu.au"
    origin_id   = "Canvas"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2", "TLSv1.1"]
    }
  }

  default_cache_behavior {
    target_origin_id = "S3-university-api"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6" // CachingOptimized
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03" // SecurityHeadersPolicy

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern = "/api/*"

    target_origin_id = "Canvas"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

    cache_policy_id            = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" // CachingDisabled
    origin_request_policy_id   = "b689b0a8-53d0-40ab-baf2-68738e2966ac" // AllViewerExceptHostHeader
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03" // SecurityHeadersPolicy

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 300
  }

  default_root_object = "index.html"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "University API"
  }

  viewer_certificate {
    acm_certificate_arn      = "arn:aws:acm:us-east-1:079464859481:certificate/9143dcea-dd3e-490f-ad72-063896607699"
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}
