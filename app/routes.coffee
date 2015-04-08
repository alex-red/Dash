path = require 'path'
os = require 'os'
request = require 'request'
disk = require 'diskspace'

module.exports = (app) ->

  app.get "/", (req, res) ->
    return res.sendFile path.join(__dirname, "../public/views/index.html")

  app.get '/disk_info', (req, res) ->
    disk.check 'C', (err, total, free, status) ->
      disk_info =
        'total': total
        'free': free
      return res.send disk_info

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
    return res.send cpuInfo

  app.use '/deluge_info', (req, res, next) ->
    toReturn = ''
    verbose = false
    ctr = 0

    options =
      method: 'POST'
      url: 'http://redserver:8112/json'
      headers:
        'Accept': 'application/json'
      json: true
      jar: true
      gzip: true
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
    .on 'end', ->
      grabInformation()

    grabInformation = ->
      options.body =
        id: 1
        method: 'web.update_ui'
        params: [[],{}]

      request options, (error, response, body) -> # Check if connected
        if error
          return console.log 'Failed to grab info - ' + error
      .on 'data', (data) ->
        if verbose
          console.log 'Torrent Info:'
          console.log data.toString()
          console.log 'Iteration ' + ctr
          ctr += 1
        toReturn += data.toString()
      .on 'end', ->
        res.send toReturn
        next()
        res.end()


    # checkConnection = ->
    #   options.body =
    #     id: 1
    #     method: 'web.connected'
    #     params: []

    #   request options, (error, response, body) -> # Check if connected
    #     if error
    #       return console.log 'Failed to connect - ' + error
    #   .on 'data', (data) ->
    #     if verbose
    #       console.log 'Connected status?'
    #       console.log data.toString()



