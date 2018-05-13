require 'rugged'

class Repo
  attr_reader :repo

  class Page
    def self.load path:, blob:
      contents = blob.content

      page = Hashie::Mash.new YAML.load contents
      page.path = path
      page.description = contents.split('---').last.strip
      page
    end
  end

  def initialize path
    @path = path
    @repo = Rugged::Repository.new path

    @initial = branches.each_with_object({}) do |b,h|
      h[b.name] = b.target.oid
    end
  end

  def user_branch user
    branches["users/#{user.name}"]
  end

  def reset
    current = branches.to_a
    current.each do |b|
      previous = @initial[b.name]
      if previous && previous != b.target.oid
        branches.delete b.name
        branches.create b.name, previous
      end
    end
  end

  def walk tree, *paths
    paths.reduce tree do |t, path|
      lookup t[path.to_s][:oid]
    end
  end

  def page commit, *paths
    blob = walk commit.tree, *paths
    Page.load path: paths.join('/'), blob: blob
  end

  def method_missing *args
    repo.public_send *args
  end
end
