class Repo
  class Page
    def self.load path:, blob:
      contents = blob.content
      page = Hashie::Mash.new YAML.load contents
      page.oid = blob.oid
      page.description = contents.split('---').last.strip
      page.path = path
      class_from_path(path).new page
    end

    def self.class_from_path path
      parts = path.split '/'
      if parts.first == 'theorems'
        Theorem
      elsif parts.first == 'properties'
        Property
      elsif parts.first == 'spaces' && parts.last == 'README.md'
        Space
      elsif parts.first == 'spaces' && parts[2] == 'properties'
        Trait
      else
        Page
      end
    end
    
    def initialize data
      @data = data
    end

    def method_missing *args
      @data.send *args
    end

    class Space < Page
    end

    class Property < Page
    end

    class Theorem < Page
      def properties
        props = Set.new
        queue = [self.if, self.then].flatten
        while f = queue.shift
          if subs = f['and'] || f['or']
            queue += subs
          else
            props.add *f.keys
          end
        end
        props.to_a
      end
    end

    class Trait < Page
    end
  end
end