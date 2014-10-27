# -*- encoding : utf-8 -*-
require "#{File.dirname(__FILE__)}/../arel/wheres"

module TinyCache
  module ActiveRecord
    module FinderMethods
      extend ActiveSupport::Concern

      included do
        class_eval do
          alias_method_chain :find_one, :tiny_cache
          alias_method_chain :find_by_attributes, :tiny_cache
        end
      end

      # TODO:
      def find_by_attributes(match, attributes, *args)
        conditions = Hash[attributes.map {|a| [a, args[attributes.index(a)]]}]
        result = where(conditions).send(match.finder)

        if match.bang? && result.nil?
          raise RecordNotFound, "Couldn't find #{@klass.name} with #{conditions.to_a.collect {|p| p.join(' = ')}.join(', ')}"
        else
          yield(result) if block_given?
          result
        end
      end

      # TODO fetch multi ids
      #
      # Cacheable:
      #
      #     current_user.articles.where(:status => 1).visiable.find(params[:id])
      #
      # Uncacheable:
      #
      #     Article.where("user_id = '1'").find(params[:id])
      #     Article.where("user_id > 1").find(params[:id])
      #     Article.where("articles.user_id = 1").find(prams[:id])
      #     Article.where("user_id = 1 AND ...").find(params[:id])
      def find_one_with_tiny_cache(id)
        return find_one_without_tiny_cache(id) unless tiny_cache_enabled?
        return find_one_without_tiny_cache(id) unless select_all_column?

        id = id.id if ActiveRecord::Base === id

        # if ::ActiveRecord::IdentityMap.enabled? && cachable? && record = from_identity_map(id)
        #   return record
        # end

        if cachable?
          if record = @klass.read_tiny_cache(id)
            return record 
          end
        end

        if cachable_without_conditions?
          if record = @klass.read_tiny_cache(id)
            return record if where_match_with_cache?(where_values, record)
          end
        end

        record = find_one_without_tiny_cache(id)
        record.write_tiny_cache
        record
      end

      # TODO cache find_or_create_by_id
      def find_by_attributes_with_tiny_cache(match, attributes, *args)
        return find_by_attributes_without_tiny_cache(match, attributes, *args) unless tiny_cache_enabled?
        return find_by_attributes_without_tiny_cache(match, attributes, *args) unless select_all_column?

        conditions = Hash[attributes.map {|a| [a, args[attributes.index(a)]]}]

        if conditions.has_key?("id")
          result = wrap_bang(match.bang?) do
            if conditions.size == 1
              find_one_with_tiny_cache(conditions["id"])
            else
              where(conditions.except("id")).find_one_with_tiny_cache(conditions["id"])
            end
          end

          yield(result) if block_given? #edge rails do this bug rails3.1.0 not

          return result
        end

        find_by_attributes_without_tiny_cache(match, attributes, *args)
      end

      private

      def wrap_bang(bang)
        bang ? yield : (yield rescue nil)
      end

      def cachable?
        where_values.blank? &&
          limit_one? && order_values.blank? &&
          includes_values.blank? && preload_values.blank? &&
          readonly_value.nil? && joins_values.blank? && !@klass.locking_enabled?
      end

      def cachable_without_conditions?
        limit_one? && order_values.blank? &&
          includes_values.blank? && preload_values.blank? &&
          readonly_value.nil? && joins_values.blank? && !@klass.locking_enabled?
      end

      def where_match_with_cache?(where_values, cache_record)
        condition = TinyCache::Arel::Wheres.new(where_values)
        return false unless condition.all_equality?
        condition.extract_pairs.all? do |pair|
          cache_record.read_attribute(pair[:left]) == pair[:right]
        end
      end

      def limit_one?
        limit_value.blank? || limit_value == 1
      end

      def select_all_column?
        select_values.blank?
      end

      # def from_identity_map(id)
      #   ::ActiveRecord::IdentityMap.get(@klass, id)
      # end
    end
  end
end
