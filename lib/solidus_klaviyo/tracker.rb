# frozen_string_literal: true

module SolidusKlaviyo
  class Tracker < SolidusTracking::Tracker
    class << self
      def from_config
        new(api_key: SolidusKlaviyo.configuration.api_key)
      end
    end

    def track(event)
      KlaviyoAPI::Events.create_event(body(event), auth)
    end

    private

    def body(event)
      {
        "data": {
          "type": "event",
          "attributes": {
            "properties": event.properties,
            "time": event.time.strftime("%Y-%m-%dT%H:%M:%S"),
            "value": event.properties['$value'],
            "value_currency": "USD",
            "metric": {
              "data": {
                "type": "metric",
                "attributes": {
                  "name": event.name
                }
              }
            },
            "profile": {
              "data": {
                "type": "profile",
                "attributes": {
                  "email": event.email
                }
              }
            }
          }
        }
      }
    end

    def auth
      { :header_params=>
          {"Authorization" => "Klaviyo-API-Key #{SolidusKlaviyo.configuration.api_key}",
           "revision" => "2024-06-15",
           "Accept"=>"application/json",
           "Content-Type"=>"application/json" },
        :debug_auth_names=>[]}
    end
  end
end
