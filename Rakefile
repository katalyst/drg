$LOAD_PATH.unshift './lib'
require 'drg'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/lib/**/*_spec.rb'
end

desc 'Run specs'
task default: :spec