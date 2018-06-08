#!/usr/bin/env ruby

# Remove deduced files from every commit
# This takes a _while_
puts 'Try out something like:'
puts 'git filter-branch --prune-empty --tree-filter "fgrep --recursive --files-with-matches --null [[Proof]] . | xargs -0 rm"  temp'
puts '(if you have time)'

exit 1

require 'manioc'
require 'pry'

require_relative '../lib/repo'

path = ARGV.shift || raise('Please provide path to repo')
repo = Repo.new path

class DeleteAutoCommits < Manioc[:repo, io: STDERR]
  def call branch_name
    branch = repo.branch branch_name
    count, total, good = 0, 0, []
    branch.each_commit do |c|
      total += 1
      if remove? c
        count += 1
      else
        good.push c.oid
      end
    end
    io.puts "Removed #{count} out of #{total} commits"
    binding.pry
  end

  def remove? commit
    return false unless commit.message.start_with? 'Update'
    return false unless commit.author[:email] == 'jamesdabbs@gmail.com'
    return false if commit.parents.none?
    raise 'Unexpected branch split' if commit.parents.count > 1
    diff = commit.parents.first.diff commit
    patches = diff.each_patch.to_a.join("\n")
    patches.include? '+[[Proof]]'
  end
end

repo = Repo.new path
DeleteAutoCommits.new(repo: repo).call \
  ARGV.shift || 'master'