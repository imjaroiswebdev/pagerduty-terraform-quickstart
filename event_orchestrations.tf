/* 
  PagerDuty Event Orchestrations Definition
  - https://support.pagerduty.com/docs/event-orchestration
  - https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/event_orchestration
  - https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/event_orchestration_router
  - https://registry.terraform.io/providers/PagerDuty/pagerduty/latest/docs/resources/event_orchestration_service
*/

/*
  Event Orchestrations: 

  These are usually managed per team basis but can be done globally.
  It should be noted that the rules within the Event Orchestrations obey a top down approach

  i.e. the first rule is executed and will stop processing if there is a match, else 
  the remaining rules are processed in descending order.

  The following user roles can create/edit/delete Event Orchestrations:

  * User
  * Admin
  * Manager base roles and team roles. Manager team roles can create/edit/delete Event Orchestrations associated with their team.
  * Global Admin
  * Account Owner
*/
resource "pagerduty_event_orchestration" "support_eo" {
  name = "Support: Ingest All Events"
  team = pagerduty_team.support.id
}

resource "pagerduty_event_orchestration_router" "support_eo_router" {
  event_orchestration = pagerduty_event_orchestration.support_eo.id
  set {
    id = "start"
    /* 
      Support Event Orchestration Routing Example 1 and 2:

      IF there is an incoming event with the support_eo routing key
      AND payload.component = website 
      AND payload.severity = warning
      THEN route alert to website service
    */
    rule {
      condition {
        expression = "event.component matches 'website' and event.severity matches 'warning'"
      }
      actions {
        route_to = pagerduty_service.example_application_website.id
      }
    }
    /* 
      Support Event Orchestration Routing Example 3:

      IF there is an incoming event with the global_eo routing key
      AND payload.component matches Google RE2 Regex `(?-i)database`
      AND payload.severity=critical
      THEN route alert to database service
    */
    rule {
      condition {
        expression = "event.component matches regex '(?-i)database' and event.severity matches 'critical'"
      }
      actions {
        route_to = pagerduty_service.example_application_database.id
      }
    }
  }
  catch_all {
    actions {
      route_to = "unrouted"
    }
  }
}

resource "pagerduty_event_orchestration_service" "example_application_website_warning" {
  service                                = pagerduty_service.example_application_website.id
  enable_event_orchestration_for_service = true
  set {
    id = "start"

    /* 
      Website Service Orchestration Rule Example 1:

      IF there is an incoming event with the support_eo routing key
      AND the current time is between 09:00 - 17:00 London, Monday to Friday
      THEN create incident
      AND update incident severity to "warning"
      AND update incident priority to "P3"
      AND update incident note
    */
    rule {
      condition {
        expression = "(now in Mon,Tue,Wed,Thu,Fri 09:00:00 to 17:00:00 Europe/London)"
      }
      actions {
        severity = "warning"
        priority = data.pagerduty_priority.p3.id
        annotate = "Routed via global rule: example_application_website_warning_0"
      }
    }
    /* 
      Website Service Orchestration Rule Example 2:

      IF there is an incoming event with the support_eo routing key
      AND the event has not matched the previous Service Orchestration rule (out of hours)
      THEN suppress alert (i.e. do not create incident)
    */
    rule {
      actions {
        suppress = true
      }
    }
  }
  catch_all {
    actions {}
  }
}

resource "pagerduty_event_orchestration_service" "example_application_database_critical" {
  service                                = pagerduty_service.example_application_database.id
  enable_event_orchestration_for_service = true
  set {
    id = "start"

    /* 
      Database Service Orchestration Rule Example 3:

      IF there is an incoming event with the support_eo routing key
      AND payload.severity=critical
      THEN create incident
      AND create template variable "Src" from payload.source
      AND extract (.*) from payload.component to dedup_key
      AND update incident summary to "Critical: Failure on Database {{Src}}" (containing temmplate variable)
      AND update incident severity to "critical"
      AND update incident priority to "P1"
      AND update incident note
    */
    rule {
      condition {
        expression = "event.severity matches 'critical'"
      }
      actions {
        variable {
          name  = "Src"
          path  = "event.source"
          value = "(.*)"
          type  = "regex"
        }
        extraction {
          source = "event.component"
          regex  = "(.*)"
          target = "event.custom_details.dedup_key"
        }
        extraction {
          template = "Critical: Failure on Database {{variables.Src}}"
          target   = "event.summary"
        }
        severity = "critical"
        priority = data.pagerduty_priority.p1.id
        annotate = "Routed via global rule: example_application_database_critical"
      }
    }
  }
  catch_all {
    actions {}
  }
}
