(function() {
  var os, path, request;

  path = require('path');

  os = require('os');

  request = require('request');

  module.exports = function(app) {
    app.get("/", function(req, res) {
      return res.sendFile(path.join(__dirname, "../public/views/index.html"));
    });
    app.get('/sys_info', function(req, res) {
      var cpuInfo;
      cpuInfo = {
        hostname: os.hostname(),
        type: os.type(),
        platform: os.platform(),
        arch: os.arch(),
        release: os.release(),
        uptime: os.uptime(),
        load: os.loadavg(),
        totalmem: os.totalmem(),
        freemem: os.freemem(),
        cpus: os.cpus(),
        network: os.networkInterfaces()
      };
      return res.send(cpuInfo);
    });
    return app.get('/deluge_info', function(req, res) {
      var checkConnection, grabInformation, options, toReturn, verbose;
      toReturn = 'Response: ';
      verbose = false;
      request = request.defaults({
        method: 'POST',
        url: 'http://redserver:8112/json',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        json: true,
        jar: true,
        gzip: true
      });
      options = {
        body: {
          id: 1,
          method: 'auth.login',
          params: ['deluge']
        }
      };
      request(options, function(error, response, body) {
        if (error) {
          return console.log('Failed to login - ' + error);
        }
      }).on('data', function(data) {
        if (verbose) {
          console.log('Authentication: ');
          console.log(data.toString());
        }
        return grabInformation();
      });
      grabInformation = function() {
        options.body = {
          id: 1,
          method: 'web.update_ui',
          params: [[], {}]
        };
        return request(options, function(error, response, body) {
          if (error) {
            return console.log('Failed to grab info - ' + error);
          }
        }).on('data', function(data) {
          if (verbose) {
            console.log('Torrent Info:');
            console.log(data.toString());
          }
          toReturn = data.toString();
          res.send(toReturn);
        });
      };
      checkConnection = function() {
        options.body = {
          id: 1,
          method: 'web.connected',
          params: []
        };
        return request(options, function(error, response, body) {
          if (error) {
            return console.log('Failed to connect - ' + error);
          }
        }).on('data', function(data) {
          if (verbose) {
            console.log('Connected status?');
            return console.log(data.toString());
          }
        });
      };
    });
  };

}).call(this);
