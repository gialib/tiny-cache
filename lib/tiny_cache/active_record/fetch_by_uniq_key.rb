# -*- encoding : utf-8 -*-
module TinyCache
  module ActiveRecord
    module FetchByUniqKey
      def tiny_cache_find_by_id id
        begin
          record = read_tiny_cache(id)
          record = self.find_by_id(id) if record.nil?
          record.write_tiny_cache if record
          record
        ensure ::ActiveRecord::RecordNotFound
          nil
        end
      end

      def tiny_cache_find_by_id! id
        tiny_cache_find_by_id(id) || raise(::ActiveRecord::RecordNotFound)
      end

      #
      # 用来根据属性进行查询缓存, 一般适合是唯一不变的条件
      # eg:
      #   1. topic.tiny_cache_find_by :uid => 1, :category_id => 2
      #
      def tiny_cache_find_by conditions={}
        uniq_cache_key = tiny_cache_uniq_key(conditions)

        # 根据cache_key获取id
        if iid = TinyCache.cache_store.read(uniq_cache_key)
          begin
            self.find iid
          ensure ::ActiveRecord::RecordNotFound
            nil
          end
        else
          record = self.where(conditions).first
          record.tap do |record|
            TinyCache.cache_store.write(uniq_cache_key, record.id)
          end if record
        end
      end

      def tiny_cache_find_by! conditions={}
        tiny_cache_find_by(conditions) || raise(::ActiveRecord::RecordNotFound)
      end

      private

      def tiny_cache_uniq_key conditions={}
        "#{::TinyCache::Config.cache_key_prefix}/model_uniq_keys/#{self.name}/#{conditions.sort.inspect}"
      end
    end
  end
end
