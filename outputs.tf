output "api_gateway_url" {
  description = "Invoke URL for the API Gateway"
  value       = aws_api_gateway_deployment.api_deployment.invoke_url
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL"
  value       = aws_wafv2_web_acl.web_acl.id
}
