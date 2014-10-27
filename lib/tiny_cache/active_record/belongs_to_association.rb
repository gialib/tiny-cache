# -*- encoding : utf-8 -*-
module TinyCache
  module ActiveRecord
    module Associations
      module BelongsToAssociation
        extend ActiveSupport::Concern
        included do
          class_eval do
            alias_method_chain :find_target, :tiny_cache
          end
        end

        def association_class
          @reflection.klass
        end

        def find_target_with_tiny_cache
          return find_target_without_tiny_cache unless klass.tiny_cache_enabled?
          cache_record = klass.read_tiny_cache(tiny_cache_key)
          return cache_record.tap{|record| set_inverse_instance(record)} if cache_record
          record = find_target_without_tiny_cache

          record.tap do |r|
            set_inverse_instance(r)
            r.write_tiny_cache
          end if record
        end

        private

        def tiny_cache_key
          owner[reflection.foreign_key]
        end
      end
    end
  end
end
