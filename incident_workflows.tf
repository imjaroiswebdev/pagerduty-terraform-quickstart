/* 
  PagerDuty Incident Workflows
  Ref: https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/incident_workflow
*/

/* 
  Major Incident Workflows (P1/P2)

  Manually and Conditional triggerable.
  Eligible to be fired from all Services on the account.
*/
resource "pagerduty_incident_workflow" "major_incident_workflow" {
  name        = "Major Incident Response"
  description = "Incident workflows for Major Incident (P1/P2)"

  step {
    name   = "Add Conference Bridge"
    action = "pagerduty.com:incident-workflows:add-conference-bridge:4"
    input {
      name  = "Conference Number"
      value = "+1-555-555-5555,,1234#"
    }
    input {
      name  = "Conference URL"
      value = "https://myconference.bridge.com/123-456-678"
    }
  }

  step {
    name   = "Add Responders"
    action = "pagerduty.com:incident-workflows:add-responders:2"
    input {
      name  = "Responders"
      value = <<JSON
      [
        {
          "id": "${pagerduty_escalation_policy.support.id}",
          "type": "escalation_policy"
        },
        {
          "id": "${pagerduty_escalation_policy.operations.id}",
          "type": "escalation_policy"
        }
      ]
JSON
    }
  }

  step {
    name   = "Add Stakeholders"
    action = "pagerduty.com:incident-workflows:add-stakeholders:2"
    input {
      name  = "Stakeholders"
      value = <<JSON
      [
        {
          "id": "${pagerduty_team.it_management.id}",
          "type": "team"
        },
        {
          "id": "${pagerduty_team.executive.id}",
          "type": "team"
        }
      ]
JSON
    }
  }

  step {
    name   = "Send Status Update"
    action = "pagerduty.com:incident-workflows:send-status-update:5"
    input {
      name  = "Message (SMS, Push and Status Page update)"
      value = "Major incident identified - teams have been mobilised"
    }
  }

}

resource "pagerduty_incident_workflow_trigger" "major_incident_wf_manual_trigger" {
  type                       = "manual"
  workflow                   = pagerduty_incident_workflow.major_incident_workflow.id
  subscribed_to_all_services = true
}

resource "pagerduty_incident_workflow_trigger" "major_incident_wf_conditional_trigger" {
  type                       = "conditional"
  workflow                   = pagerduty_incident_workflow.major_incident_workflow.id
  condition                  = "incident.priority matches '${data.pagerduty_priority.p1.name}' or incident.priority matches '${data.pagerduty_priority.p2.name}'"
  subscribed_to_all_services = true
}
