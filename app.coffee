express = require("express")
routes = require("./routes")
io = require('socket.io')

app = module.exports = express.createServer()
app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + "/public")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
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

clients = {}
io = io.listen app
io.sockets.on 'connection', (socket) ->
  console.log "Have a connection: #{socket.id}"

  socket.on 'join', (data) ->
    console.log "I can has join: #{socket.id}"
    clients[socket.id] = socket
    for id, cl of clients
      cl.emit('state', data) if (id != socket.id)

  socket.on 'state', (data) ->
    console.log "He told me that he moved #{data.moved}"
    for id, cl of clients
      cl.emit('state', data) if (id != socket.id)

  socket.on 'disconnect', ->
    console.log "He disconnected: #{socket.id}"
    delete clients[socket.id]
