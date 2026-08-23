# Modules under terraform/modules are private implementation details of this
# repository. Terraform and provider version selection lives in the root
# rather than being repeated in every module, so these two rules are off.
rule "terraform_required_version" {
  enabled = false
}

rule "terraform_required_providers" {
  enabled = false
}
