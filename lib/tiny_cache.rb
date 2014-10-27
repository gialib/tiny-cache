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

end

require 'tiny_cache/active_record' if defined?(::ActiveRecord)
