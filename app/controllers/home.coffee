Seq = require 'seq'
gravatar = require 'gravatar'

moduleList = require '../query/module_list'
tagList = require '../query/tag_list'
pkgQuery = require '../query/package'

class HomeController
  index: (req, res, next) =>
    viewdata = {}
    type = req.param "sort", ["popular"]
    tag = req.param "tag"
    type = type[0]
    tag = tag[0] if tag? and tag.length > 0
    console.log(type, tag)

    format = req.param 'format'

    Seq()
      .par(-> moduleList type, tag, this)
      .par(-> tagList this)
      .seq((mods, tags) =>
        viewdata.currentTag = tag ? 'all'
        viewdata.currentType = type
        viewdata.modules = mods
        viewdata.tags = (t._id for t in tags)
        viewdata.tags.splice(0, 0, "all")

        @attachGravatars(mods)
        @annotateScores(mods, type)

        formats = {
          html: () -> res.render('home/index', viewdata)
          json: () -> res.send(mods)
          partial: () -> res.render('home/_modules', viewdata)
        }

        if format of formats
          formats[format]()
        else
          res.format formats

      ).catch((err) ->
        next new Error(err))

  get: (req, res, next) =>
    id = req.param "pkgid"
    format = req.param 'format'

    pkgQuery id, (error, doc) =>
      return next new Error(error) if error?

      if doc.length == 0
        return res.send(404, "Not found")

      doc = doc[0]
      doc.currentType = null
      doc.currentTag = null

      formats = {
        html: () -> res.render('home/get', doc)
        json: () -> res.send(doc)
        partial: () -> res.render('home/_pkg', doc)
      }

      if format of formats
        formats[format]()
      else
        res.format formats
    

  annotateScores: (mods, scoreName) ->
    for mod in mods
      mod.score = mod.metrics[scoreName + 'Score']

  attachGravatars: (mods) ->
    for mod in mods
      mod.ownerGravatar =  gravatar.url(mod.owner ? 'nobody@example.com', { s: 120 })

  @setup: (app) =>
    my = new HomeController()
    app.param("pkgid", /[A-Za-z0-9\-\._]+/)
    app.param("tag", /[A-Za-z0-9\-\._]+/)
    app.param("sort", /(interesting|new|popular)/)

    app.get "/pkg/:pkgid.:format?", my.get
    app.get "/.:format?", my.index
    app.get "/:sort?.:format?", my.index
    app.get "/:sort?/tags/:tag.:format?", my.index

module.exports = HomeController