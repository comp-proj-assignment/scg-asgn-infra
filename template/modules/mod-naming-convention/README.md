# mod-naming-convention

Shared lookup table mapping AWS terraform resource types to the short
abbreviation used in resource names. No inputs, no logic — just a
constant other modules import so the abbreviations stay consistent.

## Usage

```hcl
module "naming" {
  source = "../../modules/mod-naming-convention"
}

locals {
  vpc_abbr = module.naming.aws_resource["aws_vpc"]   # → "vpc"
}
```

## Adding a new abbreviation

Edit `locals.tf` here. Every consuming module picks it up on the next
`terraform plan`. Keys are AWS terraform resource types
(`aws_vpc`, `aws_s3_bucket`, `aws_lb`, …); values are the short
abbreviations that go into resource names.
