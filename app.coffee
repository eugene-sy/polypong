express = require 'express'
routes = require './routes'
io = require 'socket.io'

# classes
Game = require './game/game'

# functions
detect_move = require './game/game'

app = module.exports = express.createServer()
app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session {secret: 'thisisasecretnobodyshouldseehoweverthisisdevwhowantstohackponggameanyway?' }
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + "/public")

app.configure 'development', ->
  app.use express.errorHandler(
    dumpExceptions: true, showStack: true
  )

port = process.env['app_port'] || 3000

app.configure 'production', ->
  app.use express.errorHandler()

app.get '/', routes.index
app.get '/about', routes.about
app.get '/login', routes.loginPage
app.post '/login', routes.loginAction

app.listen port

console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env

game = new Game

io = io.listen app
io.sockets.on 'connection', (socket) ->
  game.connect socket
