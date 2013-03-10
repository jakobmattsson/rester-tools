fs = require 'fs'
async = require 'async'
_ = require 'underscore'

exports.authenticateWithBasicAuthAndLocke = (locke, appName) ->
  (req, callback) ->
    return callback(null, null) if !req.headers.authorization
    code = req.headers.authorization.slice(6)
    [username, token] = new Buffer(code, "base64").toString("ascii").split(":")

    locke.authToken appName, username, token, (err, res) ->
      return callback(err) if err
      callback(null, username)


exports.getAuthorizationData = (db, authDatas) ->
  (username, callback) ->
    return callback(null, null)  unless username?
    async.map authDatas, ((dd, callback) ->
      uu = undefined
      uu = _.object([[dd.usernameProperty, username]])
      db.list dd.table, uu, (err, rr) ->
        callback err, (rr or []).map(dd.callback)

    ), (err, results) ->
      lengths = undefined
      _ref = undefined
      return callback(err, null)  if err
      lengths = (results or []).filter((x) ->
        x.length > 0
      )
      callback null, (if (_ref = lengths[0])? then _ref[0] else undefined)


exports.authUser = (authenticationFunc, authorizationFunc) ->
  (req, callback) ->
    async.waterfall [(callback) ->
      callback null, req
    , authenticationFunc, authorizationFunc], callback

exports.getAllUsernames = (db, authDatas, callback) ->
  async.map authDatas, ((collection, callback) ->
    db.list collection.table, (err, data) ->
      return callback(err)  if err
      callback null, _(data).pluck(collection.usernameProperty)

  ), callback

exports.versionMid = (packagePath, resourceName) ->
  resourceName = (if resourceName? then resourceName else "version")
  (req, res, next) ->
    return next()  if req.path isnt ("/" + resourceName)
    fs.readFile packagePath, "utf8", (err, data) ->
      return res.send(400, err.toString())  if err
      res.json version: JSON.parse(data).version

exports.replaceContentTypeMiddleware = (contentTypeMap) ->
  hasBody = (req) -> "transfer-encoding" of req.headers || "content-length" of req.headers
  (req, res, next) ->
    if hasBody(req)
      oldContentType = req.headers["content-type"] || ""
      newContentType = contentTypeMap[oldContentType]
      req.headers["content-type"] = newContentType if newContentType
    next()

exports.corsMiddleware = ->
  (req, res, next) ->
    res.header "Access-Control-Allow-Origin", "*"
    res.header "Access-Control-Allow-Methods", "GET, PUT, POST, DELETE, OPTIONS"
    res.header "Access-Control-Allow-Headers", "Content-Type, Authorization, Content-Length, X-Requested-With, Cache-Control"
    res.header "Access-Control-Allow-Credentials", "true"
    if req.method == "OPTIONS"
      res.send(200)
    else
      next()