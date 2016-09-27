# -*- encoding : utf-8 -*-
require 'active_support/all'
require 'tiny_cache/config'
require 'tiny_cache/record_marshal'

module TinyCache
  def self.configure
    block_given? ? yield(Config) : Config
  end

  class << self
    delegate :logger, :cache_store, :cache_key_prefix, :to => Config
  end

  module Mixin
    extend ActiveSupport::Concern

    module ClassMethods
      attr_reader :tiny_cache_options

      def acts_as_tiny_cached(options = {})
        @tiny_cache_enabled = true
        @tiny_cache_options = options
        @tiny_cache_options[:expires_in] ||= 4.weeks
        @tiny_cache_options[:version] ||= 0

        begin
          relation.class.send :include, ::TinyCache::ActiveRecord::FinderMethods
          include ::TinyCache::ActiveRecord::Core
        rescue Exception => e
          ::Rails.logger.error e.message
        end
      end

      def tiny_cache_enabled?
        !!@tiny_cache_enabled
      end

      def without_tiny_cache
        old, @tiny_cache_enabled = @tiny_cache_enabled, false

        yield if block_given?
      ensure
        @tiny_cache_enabled = old
      end

      def cache_store
        Config.cache_store
      end

      def logger
        Config.logger
      end

      def cache_key_prefix
        Config.cache_key_prefix
      end

      def cache_version
        (tiny_cache_options || {})[:version]
      end

      def tiny_cache_key(id)
        "#{cache_key_prefix}/#{table_name.downcase}/#{id}/#{cache_version}"
      end

      def read_tiny_cache(id)
        logger.debug " -> tiny cache read model: #{tiny_cache_key(id)}"

        RecordMarshal.load(::TinyCache.cache_store.read(tiny_cache_key(id))) if self.tiny_cache_enabled?
      end

      def expire_tiny_cache(id)
        logger.debug " -> tiny cache delete model: #{tiny_cache_key(id)}"

        ::TinyCache.cache_store.delete(tiny_cache_key(id)) if self.tiny_cache_enabled?
      end
    end

    def tiny_cache_key
      self.class.tiny_cache_key(id)
    end

    def expire_tiny_cache
      logger.debug " -> tiny cache delete model: #{tiny_cache_key}"

      ::TinyCache.cache_store.delete(tiny_cache_key) if self.class.tiny_cache_enabled?
    end

    def write_tiny_cache
      if self.class.tiny_cache_enabled?
        logger.debug " -> tiny cache write model: #{tiny_cache_key}"

        ::TinyCache.cache_store.write(
          tiny_cache_key, RecordMarshal.dump(self),
          :expires_in => self.class.tiny_cache_options[:expires_in]
        )
      end
    end

    alias update_tiny_cache write_tiny_cache
  end
end

require 'tiny_cache/active_record' if defined?(ActiveRecord)
