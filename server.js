(function() {
  var app, bodyParser, db, exports, express, methodOverride, port;

  express = require('express');

  app = express();

  bodyParser = require('body-parser');

  methodOverride = require('method-override');

  db = require('./config/db');

  port = process.env.PORT || 3000;

  app.use(express["static"](__dirname + '/public'));

  require('./app/routes')(app);

  app.get('/test', function(req, res) {
    return res.send('Test');
  });

  app.listen(port);

  exports = module.exports = app;

}).call(this);
