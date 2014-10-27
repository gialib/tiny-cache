# Tiny Cache

## for Rails3+ model cache

## 使用方法 usage:

* config
  config/initializers 下新建 tiny_cache.rb

```
  # -*- encoding : utf-8 -*-
  TinyCache.configure do |config|
    config.cache_store = ::Rails.cache
  end
```

* 在model 中调用
```
module Ruby800
  class Board < ActiveRecord::Base

    self.acts_as_tiny_cached
    
    # self.acts_as_tiny_cached :version => 2, :expires_in => 2.weeks

  end
end
```

* 生成的实例方法
...

