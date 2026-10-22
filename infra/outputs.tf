output "site_url" {
  description = "The public link to share."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "api_url" {
  value = aws_apigatewayv2_api.api.api_endpoint
}

output "site_bucket" {
  value = aws_s3_bucket.site.bucket
}

output "distribution_id" {
  value = aws_cloudfront_distribution.site.id
}

output "ecr_repository_url" {
  value = aws_ecr_repository.site.repository_url
}

output "github_deploy_role_arn" {
  description = "Put this in the GitHub repo variable AWS_DEPLOY_ROLE_ARN."
  value       = local.ci_enabled ? aws_iam_role.ci[0].arn : ""
}
