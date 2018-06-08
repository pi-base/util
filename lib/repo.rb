require 'hashie'
require 'rugged'
require 'yaml'

class Repo
  attr_reader :repo

  def initialize path
    @path = path
    @repo = Rugged::Repository.new path
  end

  def branch name, from: 'master'
    Repo::Branch.new(repo: repo, name: name, from: from)
  end

  def branch_states
    branches.each_with_object({}) do |b,h|
      h[b.name] = b.target.oid
    end
  end

  def reset initials
    current = branches.to_a
    current.each do |b|
      previous = initials[b.name]
      if previous && previous != b.target.oid
        branches.delete b.name
        branches.create b.name, previous
      end
    end
  end
end

require_relative './repo/branch'
require_relative './repo/page'