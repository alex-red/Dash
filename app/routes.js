(function() {
  var disk, os, path, request;

  path = require('path');

  os = require('os');

  request = require('request');

  disk = require('diskspace');

  module.exports = function(app) {
    app.get("/", function(req, res) {
      return res.sendFile(path.join(__dirname, "../public/views/index.html"));
    });
    app.get('/disk_info', function(req, res) {
      return disk.check('C', function(err, total, free, status) {
        var disk_info;
        disk_info = {
          'total': total,
          'free': free
        };
        return res.send(disk_info);
      });
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
    return app.use('/deluge_info', function(req, res, next) {
      var ctr, grabInformation, options, toReturn, verbose;
      toReturn = '';
      verbose = false;
      ctr = 0;
      options = {
        method: 'POST',
        url: 'http://redserver:8112/json',
        headers: {
          'Accept': 'application/json'
        },
        json: true,
        jar: true,
        gzip: true,
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
          return console.log(data.toString());
        }
      }).on('end', function() {
        return grabInformation();
      });
      return grabInformation = function() {
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
            console.log('Iteration ' + ctr);
            ctr += 1;
          }
          return toReturn += data.toString();
        }).on('end', function() {
          res.send(toReturn);
          next();
          return res.end();
        });
      };
    });
  };

}).call(this);
