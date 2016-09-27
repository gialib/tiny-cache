# -*- encoding : utf-8 -*-
module TinyCache
  module ActiveRecord
    module Core
      extend ActiveSupport::Concern

      included do
        class << self
          alias_method_chain :find, :cache
        end
      end

      module ClassMethods
        def find_with_cache(*ids)
          return all.find(ids.first) if ids.size == 1 && ids.first.is_a?(Fixnum)
          find_without_cache(*ids)
        end

        def fetch_with_ids *ids
          return where(:"#{self.primary_key}" => ids) unless self.tiny_cache_enabled?

          map_cache_keys = ids.map{|id| self.tiny_cache_key(id)}
          records_from_cache = ::TinyCache.cache_store.read_multi(*map_cache_keys)

          # NOTICE
          # Rails.cache.read_multi return hash that has keys only hitted.
          # eg. Rails.cache.read_multi(1,2,3) => {2 => hit_value, 3 => hit_value}

          hitted_ids = records_from_cache.map{|key, _| key.split("/")[2].to_i}
          missed_ids = ids.map{|x| x.to_i} - hitted_ids

          ::TinyCache::Config.logger.debug " -> tiny cache records missed ids -> #{missed_ids.inspect} | hitted ids -> #{hitted_ids.inspect}"

          if missed_ids.empty?
            RecordMarshal.load_multi(records_from_cache.values)
          else
            records_from_db = where(:"#{self.primary_key}" => missed_ids)

            records_from_db.map{|record| 
              record.write_tiny_cache
              record
            } + RecordMarshal.load_multi(records_from_cache.values)
          end
        end
      end
    end
  end
end
