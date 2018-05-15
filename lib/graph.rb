require 'graphql/client'
require 'graphql/client/http'

module Graph
  Dir = File.expand_path '../graph', __dir__

  Schema = GraphQL::Schema.from_definition File.read "#{Dir}/schema.gql"

  module Queries
    client = GraphQL::Client.new schema: Schema

    ::Dir["#{Dir}/queries/**/*.gql"].each do |path|
      m = client.parse File.read path
      m.constants.each do |name|
        Queries.const_set name, m.const_get(name)
      end
    end

    def self.each
      return enum_for :each unless block_given?
      constants.each { |n| yield [n, const_get(n)] }
    end

    extend Enumerable

    each do |name, query|
      define_method(name.to_s.underscore) { query }
    end
  end
end