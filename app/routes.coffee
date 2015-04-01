path = require 'path'
os = require 'os'
request = require 'request'

module.exports = (app) ->

  app.get "/", (req, res) ->
    res.sendFile path.join(__dirname, "../public/views/index.html")

  app.get '/sys_info', (req, res) ->
    cpuInfo =
      hostname : os.hostname()
      type : os.type()
      platform : os.platform()
      arch : os.arch()
      release : os.release()
      uptime : os.uptime()
      load : os.loadavg()
      totalmem : os.totalmem()
      freemem : os.freemem()
      cpus : os.cpus()
      network : os.networkInterfaces()
    res.send cpuInfo

  app.get '/deluge_info', (req, res) ->
    toReturn = 'Response: '
    verbose = false

    request = request.defaults {
      method: 'POST'
      url: 'http://redserver:8112/json'
      headers:
        'Content-Type': 'application/json'
        'Accept': 'application/json'
      json: true
      jar: true
      gzip: true
    }
    options =
      body:
        id: 1
        method: 'auth.login'
        params: ['deluge']

    request options, (error, response, body) -> # Login
      if error
        return console.log 'Failed to login - ' + error
    .on 'data', (data) ->
      if verbose
        console.log 'Authentication: '
        console.log data.toString()
      grabInformation()

    grabInformation = ->
      options.body =
        id: 1
        method: 'web.update_ui'
        params: [ [], {} ]

      request options, (error, response, body) -> # Check if connected
        if error
          return console.log 'Failed to grab info - ' + error
      .on 'data', (data) ->
        if verbose
          console.log 'Torrent Info:'
          console.log data.toString()
        toReturn = data.toString()
        res.send toReturn #End
        return

    checkConnection = ->
      options.body =
        id: 1
        method: 'web.connected'
        params: []

      request options, (error, response, body) -> # Check if connected
        if error
          return console.log 'Failed to connect - ' + error
      .on 'data', (data) ->
        if verbose
          console.log 'Connected status?'
          console.log data.toString()

    return



