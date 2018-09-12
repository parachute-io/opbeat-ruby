require 'logger'

module Opbeat
  class Configuration
    DEFAULTS = {
      server: "https://app.trainwreck.io".freeze,
      logger: Logger.new(nil),
      context_lines: 3,
      enabled_environments: %w{production},
      excluded_exceptions: [],
      filter_parameters: [/(authorization|password|passwd|secret)/i],
      timeout: 100,
      open_timeout: 100,
      backoff_multiplier: 2,
      use_ssl: true,
      current_user_method: :current_user,
      environment: ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'default',
      transaction_post_interval: 60,
      worker_quit_timeout: 5,

      disable_performance: false,
      disable_errors: false,

      debug_traces: false,

      view_paths: [],

      # for tests
      disable_worker: false
    }.freeze

    attr_accessor :secret_token
    attr_accessor :app_id

    attr_accessor :server
    attr_accessor :logger
    attr_accessor :context_lines
    attr_accessor :enabled_environments
    attr_accessor :excluded_exceptions
    attr_accessor :filter_parameters
    attr_accessor :timeout
    attr_accessor :open_timeout
    attr_accessor :backoff_multiplier
    attr_accessor :use_ssl
    attr_accessor :current_user_method
    attr_accessor :environment
    attr_accessor :transaction_post_interval
    attr_accessor :worker_quit_timeout

    attr_accessor :disable_performance
    attr_accessor :disable_errors

    attr_accessor :debug_traces

    attr_accessor :disable_worker

    attr_accessor :view_paths

    def initialize opts = {}
      DEFAULTS.merge(opts).each do |k, v|
        self.send("#{k}=", v)
      end

      if block_given?
        yield self
      end
    end

    def validate!
      %w{app_id secret_token}.each do |key|
        raise Error.new("Opbeat Configuration missing `#{key}'") unless self.send(key)
      end

      true
    rescue Error => e
      logger.error e.message
      false
    end
  end
end
