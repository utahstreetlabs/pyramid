require 'ladon/resource/base'

module Pyramid
  class ResourceBase < Ladon::Resource::Base
    self.base_url = 'http://127.0.0.1:4060'

    class << self
      # Force all subclasses to use the base class's base url
      def base_url
        self == ResourceBase ? super : ResourceBase.base_url
      end

      # @return [String] semicolon-delimited path segment
      def grouped_query_path_segment(ids)
        ids.sort.join(';')
      end

      # @return [Hash] (id => 0 for each id) key is entity id, value is like count
      # @see Ladon::Resource::Base#fire_get
      def fire_grouped_count_query(url, ids, options = {})
        default_data = ids.each_with_object({}) {|id, m| m[id.to_s] = 0}
        options = options.reverse_merge(default_data: default_data)
        fire_get(url, options).each_with_object(default_data.dup) {|(id, count), m| m[id.to_i] = count}
      end

      # @return [Hash] (id => 0 for each id) key is entity id, value is like count
      # @see Ladon::Resource::Base#fire_get
      def fire_recent_count_query(url, days, options = {})
        defaults = {default_data: {total: 0, results: []}, params_map: {attr: :attr}, pre_paged: true,
          params: {days: days, date: options[:date], normalize: options[:normalize], counts: options[:counts],
                   :'xlbu[]' => options[:exclude_liked_by_users]}}
        entity_class = options.delete(:entity_class)
        defaults[:results_mapper] = lambda {|attrs| entity_class.new(attrs)} if entity_class
        options = options.reverse_merge(defaults)
        results = fire_get(url, options)
        options[:counts] ? results : results.map { |m| m.values.first }
      end

      # @return [Hash] (id => false for each id) key is entity id, value is existence flag
      # @see Ladon::Resource::Base#fire_get
      def fire_grouped_existence_query(url, ids, options = {})
        default_data = ids.each_with_object({}) {|id, m| m[id] = false}
        options = options.reverse_merge(default_data: default_data)
        data = fire_get(url, options)
        data.each_with_object(default_data.dup) {|(id, flag), m| m[id.to_i] = flag}
      end

      # @return [Integer] (0)
      # @see Ladon::Resource::Base#fire_get
      def fire_count_query(url, options = {})
        options = options.reverse_merge(default_data: {count: 0})
        fire_get(url, options)[:count]
      end

      # @option options [Integer] :page
      # @option options [Integer] :per
      # @option options [Array] :attrs if present, narrows the attributes of the returned entities to just this set
      # @option options [Class] :entity_class
      # @return [Ladon::PaginatableArray] ({total: 0, results: []})
      # @see Ladon::Resource::Base#fire_get
      def fire_paged_query(url, options = {})
        defaults = {default_data: {total: 0, results: []}, params_map: {attr: :attr}, pre_paged: true}
        entity_class = options.delete(:entity_class)
        defaults[:results_mapper] = lambda {|attrs| entity_class.new(attrs)} if entity_class
        options = options.reverse_merge(defaults)
        fire_get(url, options)
      end

      # @return [+entity_class+ or nil if the entity does not exist
      # @see Ladon::Resource::Base#fire_get
      def fire_entity_get(url, entity_class, options = {})
        attrs = fire_get(url, options)
        attrs ? entity_class.new(attrs) : nil
      end

      # @return [+entity_class+] or nil if the entity could not be created
      # @see Ladon::Resource::Base#fire_put
      def fire_entity_put(url, entity_class, options = {})
        attrs = fire_put(url, options)
        attrs ? entity_class.new(attrs) : nil
      end

      def likeable_path_segment(likeable_type)
        raise ArgumentError.new('likeable type required') unless likeable_type
        likeable_type.to_s.pluralize
      end
    end
  end
end
