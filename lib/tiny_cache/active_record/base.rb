# -*- encoding : utf-8 -*-
module TinyCache
  module ActiveRecord
    module Base

      def self.included base
        base.class_eval do
          include ::ActiveSupport::Concern

          extend ClassMethods
          include InstanceMethods

          class << self
            alias_method_chain :update_counters, :tiny_cache
          end
        end
      end

      module ClassMethods
        def tiny_cache_options
          @tiny_cache_options ||= {
            :expires_in => 1.week,
            :version    => 0
          }
        end

        def acts_as_tiny_cached(*args)
          options = args.extract_options!

          @tiny_cache_enabled = true

          if options.key?(:expires_in)
            self.tiny_cache_options[:expires_in] = options[:expires_in]
          end

          if options.key?(:version)
            self.tiny_cache_options[:version] = options[:version]
          end

          after_commit :expire_tiny_cache, :on => :destroy
          after_commit :update_tiny_cache, :on => :update
          after_commit :write_tiny_cache,  :on => :create
        end

        def update_counters_with_tiny_cache(id, counters)
          update_counters_without_tiny_cache(id, counters).tap do
            Array(id).each{|i| expire_tiny_cache(i)}
          end
        end

        # 是否启用cache
        def tiny_cache_enabled?
          !!@tiny_cache_enabled
        end

        # 不启用cache
        def without_tiny_cache
          old, @tiny_cache_enabled = @tiny_cache_enabled, false

          yield if block_given?
        ensure
          @tiny_cache_enabled = old
        end

        def cache_store
          ::TinyCache::Config.cache_store
        end

        def logger
          ::TinyCache::Config.logger
        end

        def tiny_cache_key_prefix
          ::TinyCache::Config.cache_key_prefix
        end

        def tiny_cache_version
          tiny_cache_options ? tiny_cache_options[:version] : ''
        end

        def tiny_cache_key(id)
          "#{tiny_cache_key_prefix}/models/#{self.name}/#{id}/#{tiny_cache_version}"
        end

        def read_tiny_cache(id)
          RecordMarshal.load(TinyCache.cache_store.read(tiny_cache_key(id))) if self.tiny_cache_enabled?
        end

        def expire_tiny_cache(id)
          TinyCache.cache_store.delete(tiny_cache_key(id)) if self.tiny_cache_enabled?
        end

      end

      module InstanceMethods
        def try_load_from_tiny_cache
          self.class.read_tiny_cache(self.id) || self
        end

        # 缓存的key
        def tiny_cache_key
          self.class.tiny_cache_key(self.id)
        end

        def expire_tiny_cache
          self.class.expire_tiny_cache(self.id)
        end

        def tiny_cache_method_fetch *args, &block
          options = args.extract_options!

          self.class.cache_store.fetch self.tiny_cache_method_key(args), options do
            block.call
          end
        end

        def tiny_cache_method_expire *args
          args.extract_options!

          self.class.cache_store.delete self.tiny_cache_method_key(args)
        end

        def tiny_cache_method_key args
          "#{self.tiny_cache_key}/method_fetch/#{args.join('/')}"
        end

        def refresh_tiny_cache_updated_at
          self.updated_at = Time.now
        end

        def tiny_cache_expires_in
          self.class.tiny_cache_options[:expires_in]
        end

        def write_tiny_cache
          if self.class.tiny_cache_enabled?
            ::TinyCache.cache_store.write(
              self.tiny_cache_key, RecordMarshal.dump(self), :expires_in => tiny_cache_expires_in
            )
          end
        end

        alias update_tiny_cache write_tiny_cache
      end
    end
  end
end
