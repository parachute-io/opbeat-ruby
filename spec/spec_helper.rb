ENV['RACK_ENV'] = 'test'

DEBUG = ENV.fetch('CI', false)

require 'bundler/setup'
Bundler.require :default
require 'timecop'
require 'webmock/rspec'

SimpleCov.start

require 'opbeat'

module Opbeat
  class Configuration
    # Override defaults to enable http (caught by WebMock) in test env
    defaults = DEFAULTS.dup.merge enabled_environments: %w{test}
    remove_const(:DEFAULTS)
    const_set(:DEFAULTS, defaults.freeze)
  end
end

RSpec.configure do |config|
  config.backtrace_exclusion_patterns += [%r{/gems/}]

  config.before :each do
    @request_stub = stub_request(:post, /app\.trainwreck\.io/)
  end

  config.around :each, mock_time: true do |example|
    @date = Time.utc(1992, 1, 1)

    def travel distance
      Timecop.freeze(@date += distance / 1_000.0)
    end

    travel 0
    example.run
    Timecop.return
  end

  def build_config attrs = {}
    Opbeat::Configuration.new({
      app_id: 'x',
      organization_id: 'y',
      secret_token: 'z'
    }.merge(attrs))
  end

  config.around :each, start: true do |example|
    Opbeat.start! build_config
    example.call
    Opbeat::Client.inst.current_transaction = nil
    Opbeat.stop!
  end

  config.around :each, start_without_worker: true do |example|
    Opbeat.start! build_config(disable_worker: true)
    example.call
    Opbeat::Client.inst.current_transaction = nil
    Opbeat.stop!
  end
end

RSpec::Matchers.define :delegate do |method, opts|
  to = opts[:to]
  args = opts[:args]

  match do |delegator|
    unless to.respond_to?(method)
      raise NoMethodError.new("no method :#{method} on #{to}")
    end

    if args
      allow(to).to receive(method).with(*args) { true }
    else
      allow(to).to receive(method).with(no_args) { true }
    end

    delegator.send method, *args
  end

  description do
    "delegate :#{method} to #{to}"
  end
end

