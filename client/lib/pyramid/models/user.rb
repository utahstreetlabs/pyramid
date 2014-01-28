require 'ladon/model'
require 'pyramid/resources/users_resource'

module Pyramid
  class User < Ladon::Model
    def self.hot_or_not_suggestions(id)
      UsersResource.fire_get(UsersResource.user_hot_or_not_suggestions_url(id))
    end

    def self.destroy(id)
      UsersResource.fire_delete(UsersResource.user_url(id))
    end

    def self.destroy!(id)
      UsersResource.fire_delete(UsersResource.user_url(id), raise_on_error: true)
    end
  end
end
