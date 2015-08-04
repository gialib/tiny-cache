# -*- encoding : utf-8 -*-
module TinyCache
  module ActiveRecord
    module Base
      extend ActiveSupport::Concern

      included do
        after_destroy :expire_tiny_cache
        after_update :update_tiny_cache
        after_create :write_tiny_cache

        class << self
          alias_method_chain :update_counters, :cache
        end

      end

      module ClassMethods
        def update_counters_with_cache(id, counters)
          update_counters_without_cache(id, counters).tap do
            Array(id).each{|i| expire_tiny_cache(i)}
          end
        end
      end
    end
  end
end
