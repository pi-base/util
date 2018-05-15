#!/usr/bin/env ruby

require 'manioc'
require 'pry'
require 'set'

require_relative '../repo'

repo = Repo.new ARGV.shift

SIGNATURE = { 
  email: `git config user.name`.strip,
  name:  `git config user.email`.strip,
  time:  Time.now
}

class RemoveUnreferenced < Manioc[:repo, io: STDERR]
  def call branch='master'
    io.puts 'Finding pages missing references'
    missing = repo.each_page(branch).
      # allow pages with refs
      reject { |p| p.refs&.any? }.
      # allow traits which have a description
      reject { |p| p.space && p.property && !p.description.strip.empty? }

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
      end
    end

    # Update main branch with removed files
    io.puts "Removing files from #{branch} branch"
    head = repo.branches[branch].target
    base = Rugged::Commit.create repo.repo,
      tree:    head.tree.update(actions),
      author:  SIGNATURE,
      message: 'Remove pages without literature references',
      parents: [head]
    repo.references.update "refs/heads/#{branch}", base

    # Duplicate each blob to author's branches
    authored_pages.each do |email, pages|
      io.puts "Writing #{pages.count} files to users/#{email}"
      name = "users/#{email}"
      author_branch = repo.branches[name] || repo.branches.create(name, base)

      actions = pages.map do |p|
        { action: :upsert, oid: p.oid, filemode: 0100644, path: p.path }
      end

      commit = Rugged::Commit.create repo.repo,
        tree:      author_branch.target.tree.update(actions),
        author:    { email: email, name: authors.fetch(email, email), time: Time.now },
        committer: SIGNATURE,
        message:   "Move all user-submitted content to personal user branches",
        parents:   [author_branch.target]
      repo.references.update "refs/heads/#{name}", commit
    end
  end
end

RemoveUnreferenced.new(repo: repo).call