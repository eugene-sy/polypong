express = require 'express'
routes = require './routes'
io = require 'socket.io'
cookie = require 'cookie'

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

class Gamer
  constructor: (@socket) ->
  yourSide: (@side = 0) ->
    @socket.emit 'joined', @side
  heMoved: (who, where) ->
    @socket.emit 'state', where
  heQuitted: (who) ->
    console.log 'who=' + who
    @socket.emit 'quit', who

gamers = {}
count = 0

# Here is all our socket machimery.
# We have server events:
# - join - user joins the game
# - state - user updates his position
# - disconnect - user disconnects
# And we have client events, generated by server:
# - joined - tell him about success join and which side he will be playing (left or right for now)
# - state - update his and enemies position
# - quit - some user quitted

io = io.listen app

io.sockets.on 'connection', (socket) ->
  sid = cookie.parse(socket.handshake.headers.cookie)['connect.sid']
  console.log "Have a connection: #{sid} (socket id: #{socket.id})"

  socket.on 'join', (data) ->
    if sid of gamers
      gamers[sid].yourSide gamers[sid].side
      return
    if count == 2
      socket.emit 'busy'
      return
    console.log "I can has join: #{sid}"
    gamers[sid] = new Gamer socket
    gamers[sid].yourSide count
    count++

  socket.on 'state', (data) ->
    console.log "He told me that his state is #{data.state}"
    # for id, gamer of gamers
    #   gamer.heMoved gamers[socket.id], data if (id != socket.id)

  socket.on 'disconnect', ->
    console.log "Disconnected: #{sid}"
    if sid of gamers && gamers[sid].socket.id == socket.id
      delete gamers[sid]
      count--
      for id, gamer of gamers
        gamer.heQuitted sid if (id != sid)
