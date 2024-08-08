# frozen_string_literal: true

module SolidusKlaviyo
  class Subscriber
    attr_reader :api_key

    class << self
      def from_config
        new(api_key: SolidusKlaviyo.configuration.api_key)
      end
    end

    def initialize(api_key:)
      @api_key = api_key
    end

    def subscribe(list_id, email, properties = {})
      request_v3(list_id, email)
    end

    def update(list_id, email, properties = {})
      profiles = [properties.merge('email' => email)]
      request(list_id, profiles, "members")
    end

    def bulk_update(list_id, profiles)
      request(list_id, profiles, "members")
    end

    private

    def request_v3(list_id, email)
      body = { data:
                 {type: "profile-subscription-bulk-create-job",
                  attributes:
                    { custom_source: "Marketing Event",
                      profiles:
                        { data:
                            [{ type: "profile",
                               attributes:
                                 { email: email,
                                   subscriptions:
                                     { email: { marketing: { consent: "SUBSCRIBED" }}}}}]}},
                  relationships: { list: { data: { type: "list", id: list_id }}}} }
      KlaviyoAPI::Profiles.subscribe_profiles(body, v3_auth)
    end

    def v3_auth
      { :header_params=>
          {"Authorization" => "Klaviyo-API-Key #{api_key}",
           "revision" => "2024-06-15",
           "Accept"=>"application/json",
           "Content-Type"=>"application/json" },
        :debug_auth_names=>[]}
    end

    # TODO: v1 and v2 APIs are deprecated. Migrate the update endpoint and remove this.
    def request(list_id, profiles, object)
      response = HTTParty.post(
        "https://a.klaviyo.com/api/v2/list/#{list_id}/#{object}",
        body: {
          api_key: api_key,
          profiles: profiles,
        }.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
        }
      )

      unless response.success?
        case response.code
        when 429
          raise(RateLimitedError, response)
        else
          raise(SubscriptionError, response)
        end
      end

      response
    end
  end
end
