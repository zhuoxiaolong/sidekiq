require 'sidekiq/extensions/generic_proxy'

module Sidekiq
  module Extensions
    ##
    # Adds a 'delay' method to Mongoid to offload arbitrary method
    # execution to Sidekiq.  Examples:
    #
    # User.delay.delete_inactive
    # User.recent_signups.each { |user| user.delay.mark_as_awesome }
    class DelayedDocument
      include Sidekiq::Worker

      def perform(yml)
        (target, method_name, args) = YAML.load(yml)
        target.send(method_name, *args)
      end
    end

    module Mongoid
      def delay
        Proxy.new(DelayedDocument, self)
      end
    end

  end
end

module Mongoid
  module Document
    def self.included(receiver)
      receiver.extend Sidekiq::Extensions::Mongoid
    end
  end
end
