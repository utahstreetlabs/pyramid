require 'pyramid/models/base'
require 'sequel/model'

module Pyramid
  class Like < Sequel::Model
    include Pyramid::Model

    def deleted?
      deleted
    end

    def existing?
      not deleted
    end

    def visible?
      visible
    end

    def invisible?
      not visible
    end

    def kill
      update(deleted: true, tombstone: true)
    end

    def save(*args)
      begin
        super(*args)
      rescue Sequel::DatabaseError => e
        if e.message =~ /Duplicate entry '(.+)' for key '(.+)'/
          raise DuplicateLike.new($1, $2)
        else
          raise
        end
      end
    end

    class << self
      def counts_for_users(ids, options = {})
        ds = filter(user_id: ids)
        ds = ds.only_visible.only_existing
        ds = ds.only_type(options[:type]) if options[:type]
        ds = ds.group_and_count(:user_id)
        ds.each_with_object({}) {|o, m| m[o[:user_id]] = o[:count]}
      end

      def find_for_user(id, options = {})
        ds = filter(user_id: id)
        ds = ds.only_visible.only_existing
        ds = ds.order(:created_at.desc)
        ds = ds.narrow_attributes(options)
        ds = ds.only_type(options[:type]) if options[:type]
        ds.paginate(options)
      end

      def count_for_user(id, options = {})
        ds = filter(user_id: id)
        ds = ds.only_visible.only_existing
        ds = ds.only_type(options[:type]) if options[:type]
        ds.count
      end

      def existences_for_user(id, type, likeable_ids)
        type_attr = type_attribute(type)
        ds = select(:user_id, type_attr)
        ds = ds.filter(user_id: id, type_attr => likeable_ids)
        ds = ds.only_visible.only_existing
        ds = ds.group(type_attr)
        ds.each_with_object({}) {|o, m| m[o[type_attr]] = true}
      end

      def get_for_user(id, type, likeable_id, options = {})
        ds = filter(user_id: id, type_attribute(type) => likeable_id)
        ds = ds.only_visible unless options[:ignore_visibility]
        ds = ds.only_existing unless options[:ignore_deleted]
        ds.narrow_attributes(options)
        ds.first
      end

      def recent_for_likeable(type, days, options = {})
        days ||= 1
        date = options[:date]
        date = DateTime.now unless date.present?
        date = Time.at(date.to_i).to_datetime if date.is_a?(String)
        date = date.utc
        type_attr = type_attribute(type)

        if options[:normalize]
          ds = normalized_recent_query(type_attr, date - days.to_i, date - (days.to_i * 2))
        else
          ds = only_type(type)
          ds = ds.filter('created_at BETWEEN ? AND ?', date - days.to_i, date)
          ds = ds.only_existing
          ds = ds.group_and_count(type_attr)
          # use listing_id / tag_id as a secondary sort to create deterministic results
          ds = ds.order(:count.desc, type_attr.desc)
          # XXX: would be cooler if this worked for normalized as well, but not necessary at this stage
          ds = ds.filter(type_attr => options[:ids]) if options[:ids]
        end

        excluded_users = Array.wrap(options[:exclude_liked_by_users]).compact.map(&:to_i)
        # this could be a join, but I doubt it's faster and this is clearer
        ds = ds.exclude(listing_id: select(:listing_id).where(user_id: excluded_users)) if excluded_users.any?
        ds = select(type_attr).from(ds) unless options[:counts]
        ds.paginate(options)
      end

      def count_for_likeable(type, id)
        ds = filter(type_attribute(type) => id)
        ds = ds.only_visible.only_existing
        ds.count
      end

      def find_for_likeable(type, id, options = {})
        ds = filter(type_attribute(type) => id)
        ds = ds.only_visible.only_existing
        ds = ds.order(:created_at.desc)
        ds = ds.narrow_attributes(options)
        ds.paginate(options)
      end

      def counts_for_likeables(type, ids, options = {})
        type_attr = type_attribute(type)
        ds = filter(type_attr => ids)
        ds = ds.only_visible.only_existing
        ds = ds.group_and_count(type_attr)
        ds.each_with_object({}) {|o, m| m[o[type_attr]] = o[:count]}
      end

      # Returns ids of listings we'd like to show the given user in
      # the "hot or not" flow in Brooklyn.
      def hot_or_not_suggestions_for_user(user_id, options = {})
        db["
SELECT listing_id, COUNT(*) AS count, SUM(IF(user_id = :user_id, 1, 0)) AS liked
  FROM likes l JOIN (
  SELECT DISTINCT a.user_id AS uid
    FROM likes a JOIN
         likes b ON a.listing_id = b.listing_id
   WHERE b.user_id = :user_id) r
   ON l.user_id = r.uid
WHERE listing_id IS NOT NULL
GROUP BY listing_id
HAVING liked = 0
ORDER BY count DESC
LIMIT :limit
", {user_id: user_id, limit: (options[:limit] || 100)}].
          map {|h| h[:listing_id] }
      end

      def update_for_likeable(type, id, attributes)
        filter(type_attribute(type) => id).update(attributes)
      end

      def delete_all_for_user(id)
        filter(user_id: id).delete
      end

      protected
        def type_attribute(type)
          case type
          when :listing then :listing_id
          when :tag then :tag_id
          else raise InvalidLikeType.new(type)
          end
        end

        # Query that normalizes the time window's like counts by the previous time window of the same size.
        # This numerator is squared so that magnitude is factored in.
        # If denominator is 0, it defaults to 1 so that the likeable isn't ranked on a value of null
        def normalized_recent_query(type_attr, date1, date2)
          query = <<-sql
            SELECT #{type_attr},
                   POW(SUM(IF(created_at > :date1, 1, 0)), 2) /
                       GREATEST(SUM(IF(created_at BETWEEN :date2 AND :date1, 1, 0)), 1) AS rank
              FROM likes
             WHERE #{type_attr} IS NOT NULL
               AND deleted IS FALSE
               AND created_at > :date2
             GROUP BY #{type_attr}
             ORDER BY rank DESC
          sql

          with_sql(query, date1: date1, date2: date2)
        end
    end

    module LikeFiltering
      def only_type(type)
        case type
        when :listing then filter(~{listing_id: nil})
        when :tag then filter(~{tag_id: nil})
        else self
        end
      end

      def only_existing
        filter(deleted: false)
      end

      def only_visible
        filter(visible: true)
      end
    end
    dataset_module LikeFiltering

    class DuplicateLike < Exception
      attr_reader :entry, :index

      def initialize(entry, index)
        @entry = entry
        @index = index
      end
    end

    class InvalidLikeType < Exception
      attr_reader :type

      def initialize(type)
        @type = type
      end
    end
  end
end
