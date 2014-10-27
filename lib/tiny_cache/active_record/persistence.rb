# -*- encoding : utf-8 -*-
module TinyCache
  module ActiveRecord
    module Persistence
      extend ActiveSupport::Concern

      included do
        class_eval do
          alias_method_chain :reload, :tiny_cache
          alias_method_chain :touch, :tiny_cache
          alias_method_chain :update_column, :tiny_cache
        end
      end

      def update_column_with_tiny_cache(name, value)
        update_column_without_tiny_cache(name, value).tap{update_tiny_cache}
      end

      def reload_with_tiny_cache(options = nil)
        reload_without_tiny_cache(options).tap{expire_tiny_cache}
      end

      def touch_with_tiny_cache(name = nil)
        touch_without_tiny_cache(name).tap{update_tiny_cache}
      end
    end
  end
end
