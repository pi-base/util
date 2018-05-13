require 'rspec'

module SpecHelpers
  def git_reset branch:, to:
    system "cd /data/src/pi-base/data && git co #{branch} && git reset --hard #{to}"
  end

  def atom prop, value=true
    { prop.uid => value }
  end
end

RSpec.configure do |c|
  c.filter_run :focus
  c.run_all_when_everything_filtered = true

  c.include SpecHelpers
end
