package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

// Test the Terraform backend module
func TestTerraformBackend(t *testing.T) {
    // Configure Terraform options
    terraformOptions := &terraform.Options{
        TerraformDir: "../", // Path to Terraform root directory
    }

    // Clean up resources after test
    defer terraform.Destroy(t, terraformOptions)
    
    // Initialize and apply Terraform configuration
    terraform.InitAndApply(t, terraformOptions)

    // Verify the API Gateway endpoint output
    apiEndpoint := terraform.Output(t, terraformOptions, "api_endpoint")
    assert.NotEmpty(t, apiEndpoint, "API Gateway endpoint should not be empty")
}