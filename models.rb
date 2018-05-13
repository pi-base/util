require 'active_record'
require 'pg'

class Record < ActiveRecord::Base
  self.abstract_class = true
end

class User < Record
  self.table_name = 'user'

  has_many :tokens

  def active_token
    tokens.last.uuid
  end
end

class Token < Record
  self.table_name = 'token'

  belongs_to :user
end

