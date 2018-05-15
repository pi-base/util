require 'hashie'
require 'rugged'
require 'yaml'

class Repo
  attr_reader :repo

  class Page
    def self.load path:, blob:
      contents = blob.content

      page = Hashie::Mash.new YAML.load contents
      page.oid = blob.oid
      page.path = path
      page.description = contents.split('---').last.strip
      page
    end
  end

  def initialize path
    @path = path
    @repo = Rugged::Repository.new path
  end

  def user_branch user
    branches["users/#{user.name}"]
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

  def dig tree, *paths
    paths.reduce tree do |t, path|
      lookup t[path.to_s][:oid]
    end
  end

  def each_page branch='master'
    return enum_for(:each_page, branch) unless block_given?

    tree = branches[branch].target.tree
    tree.walk_blobs do |prefix, meta|
      next if prefix.empty?
      blob = repo.lookup meta[:oid]
      page = Page.load path: "#{prefix}#{meta[:name]}", blob: blob
      yield page
    end
  end

  def page commit, *paths
    blob = dig commit.tree, *paths
    Page.load path: paths.join('/'), blob: blob
  end

  def method_missing *args
    repo.public_send *args
  end
end
