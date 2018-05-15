require 'httparty'
require 'hashie'
require 'manioc'
require 'pry'
require 'rugged'

require_relative './graph'

class Client
  class << self
    attr_accessor :domain

    def boot db_url:
      require_relative './models'
      ActiveRecord::Base.establish_connection db_url
    end
  end

  ::Graph::Queries.each do |name, query|
    name_ = name.to_s.underscore
    define_method name_ do |**variables|
      result = execute(query, variables: variables).public_send(name_)
      update_patch result
      result
    end
  end

  attr_reader :user, :branch, :sha

  def initialize domain: nil
    @domain = domain || Client.domain

    # N.B. it's probably better to have one HTTP and one Client object,
    # but we explicitly want to test concurrent access and want to avoid
    # the possibility of either of these queueing connections
    @http = GraphQL::Client::HTTP.new "#@domain/graphql" do
      def headers context
        if user = context[:user]
          { 'Authorization' => "Bearer #{user.active_token}" }
        end
      end
    end

    @client = GraphQL::Client.new schema: Graph::Schema, execute: @http
  end

  def login user
    @user = user
  end

  def checkout name
    branch = me.branches.find { |b| b.name == name }
    raise unless branch
    @branch, @sha = branch.name, branch.sha
  end

  def sign_up name
    response = HTTParty.post "#@domain/users", 
      headers: { 'Content-Type': 'application/json' },
      body: { ident: name }.to_json
    data = Hashie::Mash.new JSON.parse response.body
    login User.find data.user.id
    data
  end

  def execute query, **opts
    opts[:context] ||= {}
    opts[:context][:user] = @user

    if @sha
      opts[:variables][:patch] ||= {}
      opts[:variables][:patch][:branch] ||= @branch
      opts[:variables][:patch][:sha] ||= @sha
    end

    result = @client.query query, **opts
    if result.data
      result.data
    else
      raise "#{query.name}: #{result.errors.messages.inspect}"
    end
  end

  def update_patch result
    @sha = result.version
  rescue
  end
end