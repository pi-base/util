class Repo
  class Branch
    attr_reader :name

    def initialize repo:, name:, from: 'master'
      @repo, @name = repo, name
      @branch = @repo.branches[name] || @repo.branches.create(name, from)
    end

    def update actions, **opts
      opts.merge! \
        tree:       tree.update(actions),
        update_ref: "refs/heads/#{@name}",
        parents:    [@branch.target]
      Rugged::Commit.create @repo, opts
      @branch = @repo.branches[name]
    end

    def self.enumerate name, prefix: nil, regex: nil
      prefix ||= name
      define_method name do |&block|
        return enum_for name if block.nil?
        each_page(prefix: prefix, regex: regex) { |page| block.call page }
      end
    end

    enumerate :spaces, regex: /README.md$/
    enumerate :properties
    enumerate :theorems
    enumerate :traits, prefix: 'spaces', regex: /\/properties\//

    def each_page prefix:, regex:
      dig(prefix).walk_blobs do |root, meta|
        path = "#{prefix}/#{root}#{meta[:name]}"
        if regex
          next unless regex.match? path
        end
        page = Repo::Page.load path: path, blob: lookup(meta[:oid])
        yield page
      end
    end

    def each_commit
      return enum_for :each_commit unless block_given?
      queue = [@branch.target]
      while commit = queue.shift
        queue += commit.parents
        yield commit
      end
    end

    def head
      @branch.target.oid
    end

    private

    def tree
      @branch.target.tree
    end

    def dig *paths
      paths.reduce tree do |t, path|
        lookup t[path.to_s][:oid]
      end
    end

    def lookup oid
      @repo.lookup oid
    end
  end
end