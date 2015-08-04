# -*- encoding : utf-8 -*-
require 'tiny_cache/active_record/base'
require 'tiny_cache/active_record/core'
require 'tiny_cache/active_record/fetch_by_uniq_key'
require 'tiny_cache/active_record/finder_methods'
require 'tiny_cache/active_record/persistence'
require 'tiny_cache/active_record/belongs_to_association'
require 'tiny_cache/active_record/has_one_association'
require 'tiny_cache/active_record/preloader'

ActiveRecord::Base.send(:include, TinyCache::Mixin)
ActiveRecord::Base.send(:include, TinyCache::ActiveRecord::Base)
ActiveRecord::Base.send(:extend, TinyCache::ActiveRecord::FetchByUniqKey)

ActiveRecord::Base.send(:include, TinyCache::ActiveRecord::Persistence)
ActiveRecord::Associations::BelongsToAssociation.send(:include, TinyCache::ActiveRecord::Associations::BelongsToAssociation)
ActiveRecord::Associations::HasOneAssociation.send(:include, TinyCache::ActiveRecord::Associations::HasOneAssociation)
ActiveRecord::Associations::Preloader::BelongsTo.send(:include, TinyCache::ActiveRecord::Associations::Preloader::BelongsTo)
