# -*- encoding : utf-8 -*-
require "#{File.dirname(__FILE__)}/active_record/base"
require "#{File.dirname(__FILE__)}/active_record/fetch_by_uniq_key"
require "#{File.dirname(__FILE__)}/active_record/finder_methods"
require "#{File.dirname(__FILE__)}/active_record/persistence"
require "#{File.dirname(__FILE__)}/active_record/belongs_to_association"
require "#{File.dirname(__FILE__)}/active_record/has_one_association"

if defined?(ActiveRecord::Base)
  ::ActiveRecord::Base.send(:include,                               ::TinyCache::ActiveRecord::Base)
  ::ActiveRecord::Base.send(:extend,                                ::TinyCache::ActiveRecord::FetchByUniqKey)
  ::ActiveRecord::Relation.send(:include,                           ::TinyCache::ActiveRecord::FinderMethods)
  ::ActiveRecord::Base.send(:include,                               ::TinyCache::ActiveRecord::Persistence)
  ::ActiveRecord::Associations::BelongsToAssociation.send(:include, ::TinyCache::ActiveRecord::Associations::BelongsToAssociation)
  ::ActiveRecord::Associations::HasOneAssociation.send(:include,    ::TinyCache::ActiveRecord::Associations::HasOneAssociation)
end
