cacheManager = require 'cache-manager'

# initing cache settings with settings
# REFACTOR switch to reddis?
cache = cacheManager.caching store: 'memory', max: 100, ttl: 10

module.exports = cache
