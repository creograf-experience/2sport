fs = require 'fs-extra'
path = require 'path'
async = require 'async'
mime = require 'mime'

# dir where we are managing files
publicDir = path.join process.cwd(), 'public'

# hardcoded allowed dirs in public/*
allowedRoutes = ['uploads']

# takes a filename and stat.isDirectory()
# and returns the type of a node
nodeType = (nodepath, isDirectory) ->
  return 'directory' if isDirectory
  return mime.lookup(nodepath).split('/')[0]

# we are changing relative fs path to web path,
# and for some reason saving isDirectory 2 times
buildNode = (nodepath, stat) ->
  path: nodepath.replace publicDir, ''
  type: nodeType(nodepath, stat.isDirectory())
  name: path.basename(nodepath)
  size: stat.size
  isDirectory: stat.isDirectory()

# the Recursive Thing, does Important Stuff.
# actually, it generates a directory tree for
# the dir tree widget
walkDir = (dir, done) ->
  fs.readdir dir, (err, list) ->
    return done(err) if err

    async.map list, ((filename, next) ->
      filepath = path.join(dir, filename)

      fs.stat filepath, (err, stat) ->
        return next(null, node) unless stat.isDirectory()

        node = buildNode(filepath, stat)
        walkDir filepath, (err, items) ->
          node.items = items
          next(null, node)

    ), (err, nodes) ->
      nodes = nodes.filter (node) -> node != undefined
      if dir == publicDir
        nodes = nodes.filter (node) -> node.name in allowedRoutes
      done(err, nodes)

# returns the dir's contents
listDir = (dir, done) ->
  dir ?= ''
  fullDirPath = path.join(publicDir, dir)
  fs.readdir fullDirPath, (err, list) ->
    return done(err) if err

    async.map list, ((filename, next) ->
      filepath = path.join(fullDirPath, filename)

      fs.stat filepath, (err, stat) ->
        return next(err) if err

        node = buildNode filepath, stat
        next(null, node)

    ), (err, nodes) ->
      if fullDirPath.match /public\/?$/
        nodes = nodes.filter (node) -> node.name in allowedRoutes
      done(err, nodes)

createDir = (urlPath, done) ->
  urlPath ?= ''
  fs.ensureDir path.join(publicDir, urlPath), done

uploadFiles = (file, ulrPath, done) ->
  ulrPath ?= 'uploads'
  uploadPath = path.join(publicDir, ulrPath, file.name)
  fs.copy file.path, uploadPath, done

removeDir = (urlPath, done) ->
  return done(new Error('path has to be specified')) unless urlPath
  allowed = allowedRoutes.reduce ((allowed, allowedDir) ->
    !!(allowed || urlPath.match new RegExp("^\/?#{allowedDir}"))
  ), false
  return done(new Error('not allowed')) unless allowed
  fs.remove path.join(publicDir, urlPath), done

module.exports =
  getDirTree: (done) ->
    walkDir publicDir, (err, nodes) ->
      done(err, items: nodes)
  listDir: listDir
  createDir: createDir
  removeDir: removeDir
  uploadFiles: uploadFiles
