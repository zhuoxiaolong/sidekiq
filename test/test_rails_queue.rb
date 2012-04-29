require 'helper'
require 'rails'
require 'sidekiq/rails'

class Job
  include Sidekiq::Worker
  def initialize(*args)
    @args = args
  end
  def run
    p [:running!, @args]
  end
end

if Rails.version > '4'
  class TestApp < Rails::Application
    config.queue = Sidekiq::Client::Queue
  end

  class TestRailsQueue < MiniTest::Unit::TestCase
    describe 'Rails.queue' do
      it 'should accept Sidekiq' do
        Rails.queue.push Job.new('wow', 'it works!')
      end
    end
  end
end
