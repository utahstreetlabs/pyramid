require 'pyramid/resources/base'

module Pyramid
  class RootResource < ResourceBase
    # Deletes everything in the entire database. Think three times before you call this!
    def self.nuke
      fire_delete('/')
    end
  end
end
