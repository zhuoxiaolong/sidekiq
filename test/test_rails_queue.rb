require 'helper'
require 'rails'
require 'sidekiq/rails'

class WorkerJob
  include Sidekiq::Worker
  def initialize(*args)
    @args = args
  end
  def run
    p [:running!, @args]
  end
end

class BareJob
  def initialize(*args)
    @args = args
  end
  def run
    p [:running!, @args]
  end
end

if Rails.version > '4'
  class TestApp < Rails::Application
    config.queue = Sidekiq::Client::Queue.new
  end

  class TestRailsQueue < MiniTest::Unit::TestCase
    describe 'Rails.queue' do
      it 'accepts Sidekiq worker instances' do
        Rails.queue.push WorkerJob.new('wow', 'it works!')
      end
      it 'accepts plain instances' do
        Rails.queue.push BareJob.new('wow', 'it works!')
      end
    end
  end
end
