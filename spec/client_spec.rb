require 'spec_helper'

require_relative '../client'
require_relative '../repo'

Client.domain = 'http://localhost:3141'
Client.boot db_url: "postgresql://localhost:5432/pi_base_development"

# These specs assume that a copy of the server is running on the configured domain
# in `test mode` (allowing signups without oauth)

RSpec.describe Client do
  let(:repo) { Repos::Working }

  around :each do |ex|
    initials = repo.branch_states
    ex.call
    repo.reset initials
  end

  xit 'can fetch branches' do
    g = client 'jamesdabbs@gmail.com'
    result = g.me
    expect(result.name).to eq 'jamesdabbs'
    expect(result.branches.map(&:name).sort).to eq %w( development master users/jamesdabbs )
  end

  xit 'can create a space on a user branch' do
    client = Client.new
    client.sign_up 'a'
    client.checkout 'users/a'

    result = client.create_space space: { uid: SecureRandom.uuid, name: 'A', description: 'A space' }

    expect(result.spaces.count).to eq 1
    space = result.spaces.first
    expect(space.name).to eq 'A'

    commit = repo.branches['users/a'].target
    expect(result.version).to eq client.sha
    expect(commit.oid).to eq client.sha
    expect(commit.message).to eq 'Add A'

    page = repo.page commit, 'spaces', space.uid, 'README.md'
    expect(page.name).to eq 'A'
    expect(page.description).to eq 'A space'
  end

  it 'handles concurrent writes' do
    clients = 50.times.map do |i|
      client = Client.new
      client.sign_up "c#{i}"
      client.checkout "users/c#{i}"
      client
    end

    clients.each do |c|
      fork do
        name = c.user.name
        result = c.create_space space: { uid: SecureRandom.uuid, name: name, description: name }
        expect(result.spaces.first.name).to eq name
      end
    end

    Process.waitall

    clients.each do |c|
      head = repo.user_branch(c.user).target
      expect(head.message). to eq "Add #{c.user.name}"
    end
  end
end
