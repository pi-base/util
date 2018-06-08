require 'rspec'
require 'pry'

require_relative '../lib/repo'

DATA_DIR = File.expand_path '../data'

module SpecHelpers
  def atom prop, value=true
    { prop.uid => value }
  end
end

module Repos
  Working    = Repo.new "#{DATA_DIR}/repo.git"
  Downstream = Repo.new "#{DATA_DIR}/downstream.git"
end

RSpec.configure do |c|
  c.filter_run :focus
  c.run_all_when_everything_filtered = true

  c.include SpecHelpers
end
