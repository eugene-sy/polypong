// Generated by CoffeeScript 1.3.3
(function() {
  var Gamer, app, cookie, count, express, gamers, io, port, routes,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  express = require('express');

  routes = require('./routes');

  io = require('socket.io');

  cookie = require('cookie');

  app = module.exports = express.createServer();

  app.configure(function() {
    app.set("views", __dirname + "/views");
    app.set("view engine", "jade");
    app.use(express.bodyParser());
    app.use(express.cookieParser());
    app.use(express.session({
      secret: 'thisisasecretnobodyshouldseehoweverthisisdevwhowantstohackponggameanyway?'
    }));
    app.use(express.methodOverride());
    app.use(app.router);
    return app.use(express["static"](__dirname + "/public"));
  });

  app.configure('development', function() {
    return app.use(express.errorHandler({
      dumpExceptions: true,
      showStack: true
    }));
  });

  port = process.env['app_port'] || 3000;

  app.configure('production', function() {
    return app.use(express.errorHandler());
  });

  app.get('/', routes.index);

  app.get('/about', routes.about);

  app.get('/login', routes.loginPage);

  app.post('/login', routes.loginAction);

  app.listen(port);

  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);

  Gamer = (function() {

    function Gamer(socket) {
      this.socket = socket;
    }

    Gamer.prototype.yourSide = function(side) {
      this.side = side != null ? side : 0;
      return this.socket.emit('joined', this.side);
    };

    Gamer.prototype.heMoved = function(who, where) {
      return this.socket.emit('state', where);
    };

    Gamer.prototype.heQuitted = function(who) {
      console.log('who=' + who);
      return this.socket.emit('quit', who);
    };

    return Gamer;

  })();

  gamers = {};

  count = 0;

  io = io.listen(app);

  io.sockets.on('connection', function(socket) {
    var sid;
    sid = cookie.parse(socket.handshake.headers.cookie)['connect.sid'];
    console.log("Have a connection: " + sid + " (socket id: " + socket.id + ")");
    socket.on('join', function(data) {
      if (__indexOf.call(gamers, sid) >= 0) {
        gamers[sid].yourSide(gamers[sid].side);
        return;
      }
      if (count === 2) {
        socket.emit('busy');
        return;
      }
      console.log("I can has join: " + sid);
      gamers[sid] = new Gamer(socket);
      gamers[sid].yourSide(count);
      return count++;
    });
    socket.on('state', function(data) {
      return console.log("He told me that his state is " + data.state);
    });
    return socket.on('disconnect', function() {
      var gamer, id, _results;
      console.log("Disconnected: " + sid);
      if (gamers[sid]) {
        delete gamers[sid];
        count--;
      }
      _results = [];
      for (id in gamers) {
        gamer = gamers[id];
        if (id !== sid) {
          _results.push(gamer.heQuitted(sid));
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    });
  });

}).call(this);
