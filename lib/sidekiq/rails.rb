module Sidekiq
  def self.hook_rails!
    return unless Sidekiq.options[:enable_rails_extensions]
    if defined?(ActiveRecord)
      ActiveRecord::Base.extend(Sidekiq::Extensions::ActiveRecord)
      ActiveRecord::Base.send(:include, Sidekiq::Extensions::ActiveRecord)
    end

    if defined?(ActionMailer)
      ActionMailer::Base.extend(Sidekiq::Extensions::ActionMailer)
    end
  end

  class Rails < ::Rails::Engine
    config.autoload_paths << File.expand_path("#{config.root}/app/workers") if File.exist?("#{config.root}/app/workers")
    config.queue = Sidekiq::Client::Queue if ::Rails.version > '4'

    initializer 'sidekiq' do
      Sidekiq.hook_rails!
    end
  end if defined?(::Rails)

  # Ugh, using Marshal is the only reliable way to shuttle the
  # instance out of process but makes the value opaque so the message
  # isn't readable, e.g. when inspecting an error.
  class RailsProxyWorker
    include Sidekiq::Worker
    def perform(blob)
      job = Marshal.load(blob)
      job.run
    end
  end

  class Client
    class Queue
      def push(data)
        options = data.is_a?(Sidekiq::Worker) ?
          data.class.get_sidekiq_options : Sidekiq::Worker::DEFAULT_SIDEKIQ_OPTIONS
        Sidekiq::Client.push(options.merge('class' => RailsProxyWorker, 'args' => [Marshal.dump(data)]))
      end
    end
  end
end
