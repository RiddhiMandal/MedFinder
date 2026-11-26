ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "support/fake_anthropic_client"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all

    # Claude provider wired to a fake client: no network, no API key.
    def claude(client) = Llm::AnthropicProvider.new(client: client)
  end
end
