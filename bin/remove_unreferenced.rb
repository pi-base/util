#!/usr/bin/env ruby

# * Scans the head of the master branch for any files describing an object
#   but missing a literature citation
# * Copies each of those files to each user branch for the users that 
#   contributed to the file
# * Adds any other references necessary so that each branch is valid
# * Removes each of those files from the master branch

require 'manioc'
require 'pry'
require 'set'

require_relative '../lib/repo'

path = ARGV.shift || raise('Please provide path to repo')
repo = Repo.new path

SIGNATURE = { 
  email: `git config user.name`.strip,
  name:  `git config user.email`.strip,
  time:  Time.now
}

module Enumerable
  def index_by &block
    each_with_object({}) { |val, h| h[block.call val] = val }
  end
end

class RemoveUnreferenced < Manioc[:repo, io: STDERR]
  def call branch='master'
    main = repo.branch branch

    io.puts 'Finding pages missing references'

    space_index    = main.spaces.index_by &:uid
    property_index = main.properties.index_by &:uid

    no_refs = ->(obj) { !obj.refs&.any? }
    spaces     = space_index.values.select &no_refs
    properties = property_index.values.select &no_refs

    sids = Set.new spaces.map &:uid
    pids = Set.new properties.map &:uid

    traits = main.traits.select do |t|
      no_refs.(t) || sids.include?(t.space) || pids.include?(t.property)
    end

    theorems = main.theorems.select do |t|
      no_refs.(t) || t.properties.any? { |p| pids.include? p }
    end

    missing = spaces + properties + theorems + traits

    return if missing.none?

    io.puts "Finding authors for #{missing.count} pages"
    authors, authored_pages, actions = {}, {}, []
    missing.each do |page|
      actions.push(action: :remove, path: page.path)
      blame = Rugged::Blame.new(repo.repo, page.path)
      blame.each do |hunk|
        signature = hunk[:final_signature]
        email     = signature[:email]
        authors[email] ||= signature[:name]
        authored_pages[email] ||= Set.new
        authored_pages[email].add page

        if page.is_a? Repo::Page::Trait
          authored_pages[email].merge [
            space_index.fetch(page.space),
            property_index.fetch(page.property)
          ]
        elsif page.is_a? Repo::Page::Theorem
          authored_pages[email].merge page.properties.map { |pid| property_index.fetch pid }
        end
      end
    end

    binding.pry

    # Update main branch with removed files
    io.puts "Removing files from #{main.name} branch"
    actions.each do |action|
      io.puts "* #{action[:path]}"
    end
    main.update actions,
      author:  SIGNATURE,
      message: 'Remove pages without literature references'

    # Duplicate each blob to author's branches
    authored_pages.each do |email, pages|
      author_branch = repo.branch("users/#{email}", from: main.head)
      io.puts "Writing #{pages.count} files to #{author_branch.name}"

      actions = pages.map do |p|
        { action: :upsert, oid: p.oid, filemode: 0100644, path: p.path }
      end

      author_branch.update actions,
        author:    { email: email, name: authors.fetch(email, email), time: Time.now },
        committer: SIGNATURE,
        message:   "Move all user-submitted content to personal user branches"
    end
  end
end

RemoveUnreferenced.new(repo: repo).call