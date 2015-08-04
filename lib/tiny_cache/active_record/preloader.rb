# -*- encoding : utf-8 -*-
module TinyCache
  module ActiveRecord
    module Associations
      class Preloader
        module BelongsTo
          extend ActiveSupport::Concern

          included do
            alias_method_chain :records_for, :tiny_cache
          end

          def records_for_with_tiny_cache(ids)
            return records_for_without_tiny_cache(ids) unless klass.tiny_cache_enabled?

            map_cache_keys = ids.map{|id| klass.tiny_cache_key(id)}
            records_from_cache = ::TinyCache.cache_store.read_multi(*map_cache_keys)
            # NOTICE
            # Rails.cache.read_multi return hash that has keys only hitted.
            # eg. Rails.cache.read_multi(1,2,3) => {2 => hit_value, 3 => hit_value}
            hitted_ids = records_from_cache.map{|key, _| key.split("/")[2].to_i}
            missed_ids = ids.map{|x| x.to_i} - hitted_ids

            ::TinyCache::Config.logger.info "missed ids -> #{missed_ids.inspect} | hitted ids -> #{hitted_ids.inspect}"

            if missed_ids.empty?
              RecordMarshal.load_multi(records_from_cache.values)
            else
              records_from_db = records_for_without_tiny_cache(missed_ids)
              records_from_db.map{|record| write_cache(record); record} + RecordMarshal.load_multi(records_from_cache.values)
            end
          end

          private

          def write_cache(record)
            record.write_tiny_cache
          end
        end
      end
    end
  end
end
