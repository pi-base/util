require 'spec_helper'

RSpec.describe Repo do
  let(:repo)   { Repos::Working }
  let(:branch) { repo.branch 'master' }

  it 'can find spaces' do
    spaces = branch.spaces.to_a
    expect(spaces.count).to be_between 100, 200
    expect(spaces).to all be_a Repo::Page::Space
    expect(spaces.map &:name).to include 'Discrete topology on a two-point set'
  end

  it 'can find properties' do
    properties = branch.properties.to_a
    expect(properties.count).to be_between 50, 150
    expect(properties).to all be_a Repo::Page::Property
    expect(properties.map &:name).to include 'Compact', 'Metrizable'
  end

  it 'can find theorems' do
    theorems = branch.theorems.to_a
    expect(theorems.count).to be_between 100, 250
    expect(theorems).to all be_a Repo::Page::Theorem
  end

  it 'can find traits' do
    traits = branch.traits.to_a
    expect(traits.count).to be > 1_000
    expect(traits).to all be_a Repo::Page::Trait
    binding.pry
  end
end