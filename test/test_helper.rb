ENV["RAILS_ENV"] ||= "test"
require "simplecov"
SimpleCov.start "rails" do
  command_name "Unit/Integration Tests"
  use_merging true
  merge_timeout 3600
  add_filter "app/mailers/application_mailer.rb"
  add_filter do |source_file|
    source_file.filename.include?("application_controller") &&
    source_file.lines.none? { |l| l.covered? }
  end
  enable_coverage :branch
end

require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  
  # Esto le dice a SimpleCov el nombre de cada proceso paralelo
  parallelize_setup do |worker|
    SimpleCov.command_name "Unit/Integration Tests (worker #{worker})"
  end
  
  parallelize_teardown do |worker|
    SimpleCov.result
  end
  
  include Devise::Test::IntegrationHelpers
end