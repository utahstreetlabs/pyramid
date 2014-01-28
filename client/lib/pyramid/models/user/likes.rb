require 'pyramid/models/like'
require 'pyramid/resources/users_resource'

module Pyramid
  class User < Ladon::Model
    class Likes
      class << self
        # @option options [Symbol] :type returns likes for likeables of a specified type only
        # @return [Ladon::PaginatableArray] ({total: 0, results: []})
        # @see Pyramid::ResourceBase#fire_paged_query
        def find(id, options = {})
          likeable_type, options = extract_type_from_options!(options)
          options[:entity_class] = Pyramid::Like
          if likeable_type
            UsersResource.fire_paged_query(UsersResource.user_likeable_likes_url(likeable_type, id), options)
          else
            UsersResource.fire_paged_query(UsersResource.user_likes_url(id), options)
          end
        end

        # @option options [Symbol] :type returns count for likeables of a specified type only
        # @return [Integer] (0)
        # @see Pyramid::ResourceBase#fire_count_query
        def count(id, options = {})
          likeable_type, options = extract_type_from_options!(options)
          if likeable_type
            UsersResource.fire_count_query(UsersResource.user_likeable_likes_count_url(likeable_type, id), options)
          else
            UsersResource.fire_count_query(UsersResource.user_likes_count_url(id), options)
          end
        end

        # @option options [Symbol] :type returns counts for likeables of a specified type only
        # @return [Hash] (id => 0 for each id)
        # @see Pyramid::ResourceBase#fire_grouped_count_query
        def count_many(ids, options = {})
          likeable_type, options = extract_type_from_options!(options)
          url = if likeable_type
            UsersResource.users_likeable_likes_count_url(likeable_type, ids)
          else
            UsersResource.users_likes_count_url(ids)
          end
          UsersResource.fire_grouped_count_query(url, ids, options)
        end

        # @return [Hash] (id => false for each id)
        # @see Pyramid::ResourceBase#fire_grouped_count_query
        def existences(id, likeable_type, likeable_ids, options = {})
          url = UsersResource.user_likeables_likes_existences_url(likeable_type, id, likeable_ids)
          UsersResource.fire_grouped_existence_query(url, likeable_ids, options)
        end

        # @return [Pyramid::Like] or +nil+ if the like does not exist
        # @see Pyramid::ResourceBase#fire_entity_get
        def get(id, likeable_type, likeable_id, options = {})
          UsersResource.fire_entity_get(UsersResource.user_likeable_like_url(likeable_type, id, likeable_id),
            Pyramid::Like, options)
        end

        # @return [Pyramid::Like] or +nil+ if the like could not be created
        # @see Pyramid::ResourceBase#fire_entity_put
        def create(id, likeable_type, likeable_id, options = {})
          UsersResource.fire_entity_put(UsersResource.user_likeable_like_url(likeable_type, id, likeable_id),
            Pyramid::Like, options)
        end

        # @see Ladon::Resource::Base#fire_delete
        def destroy(id, likeable_type, likeable_id, options = {})
          UsersResource.fire_delete(UsersResource.user_likeable_like_url(likeable_type, id, likeable_id), options)
        end

        # Makes the like visible if not already so.
        #
        # @see Ladon::Resource::Base#fire_put
        def reveal(id, likeable_type, likeable_id, options = {})
          url = UsersResource.user_likeable_like_visibility_url(likeable_type, id, likeable_id)
          UsersResource.fire_put(url, options)
        end

        # Makes the like invisible if not already so.
        #
        # @see Ladon::Resource::Base#fire_delete
        def hide(id, likeable_type, likeable_id, options = {})
          url = UsersResource.user_likeable_like_visibility_url(likeable_type, id, likeable_id)
          UsersResource.fire_delete(url, options)
        end

        protected
          def extract_type_from_options!(options)
            type = options.delete(:type)
            [type, options]
          end
      end
    end
  end
end
