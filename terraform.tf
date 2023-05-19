terraform {
  required_version = ">= 0.13.0"
  required_providers {
    pagerduty = {
      source  = "pagerduty/pagerduty"
      version = "2.14.5"
    }
  }
}

