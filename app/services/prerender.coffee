prerender = require 'prerender'

server = prerender
  workers: process.env.PHANTOM_CLUSTER_NUM_WORKERS
  iterations: process.env.PHANTOM_WORKER_ITERATIONS || 10
  phantomBasePort: process.env.PHANTOM_CLUSTER_BASE_PORT || 12300
  messageTimeout: process.env.PHANTOM_CLUSTER_MESSAGE_TIMEOUT
  port: 1337

server.use(prerender.blacklist())
server.use(prerender.removeScriptTags())
server.use(prerender.httpHeaders())

server.start()
