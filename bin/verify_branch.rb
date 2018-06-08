#!/usr/bin/env ruby

require 'pry'
require 'set'

require_relative '../lib/repo'

repo   = Repo.new(ARGV.shift || raise('Path to repo required'))
branch = ARGV.shift || raise('Branch name required')

class VerifyBranch
  attr_reader :branch, :io, :errors

  def initialize branch, io: STDERR
    @branch, @io = branch, io
    @errors = []
  end

  def call
    sids, pids = Set.new, Set.new
    branch.spaces.each do |space|
      sids.add space.uid
    end

    branch.properties.each do |property|
      pids.add property.uid
    end

    branch.traits.each do |trait|
      assert sids.include?(trait.space), "#{trait.path}: space not found"
      assert pids.include?(trait.property), "#{trait.path}: property not found"
    end

    branch.theorems.each do |theorem|
      theorem.properties.each do |property|
        assert pids.include?(property), "#{theorem.path}: property not found #{property}"
      end
    end

    if errors.any?
      io.puts "Found #{errors.count} errors:"
      io.puts errors
    else
      io.puts "#{branch.name} looks good!"
    end
  end

  private

  def assert val, msg
    errors.push msg unless val
  end
end

if branch == 'users/*'
  repo.repo.branches.map(&:name).each do |name|
    next unless name.start_with? 'users/'
    puts "Verifying #{name}"
    VerifyBranch.new(repo.branch name).call
    puts
  end
else
  VerifyBranch.new(repo.branch branch).call
end