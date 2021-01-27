resource "aws_s3_bucket" "news" {
  bucket = "${var.prefix}-terraform-infra-static-pages"
  acl    = "public-read"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_policy" "news" {
  bucket = "${aws_s3_bucket.news.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "newsBucketPolicy",
  "Statement": [
    {
      "Sid":"PublicReadGetObject",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["${aws_s3_bucket.news.arn}/*"]
    },
    {
      "Sid": "AllowBucketAccess",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.news.arn}"
    }
  ]
}
POLICY
}
