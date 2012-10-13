# Here is all our socket machimery.
# We have server events:
# - join - user joins the game
# - state - user updates his position
# - disconnect - user disconnects
# And we have client events, generated by server:
# - joined - tell him about success join and which side he will be playing (left or right for now)
# - state - update his and enemies position
# - quit - some user quitted

GameCore = require './game.core'
cookie = require 'cookie'
timers = require 'timers'

module.exports = class Game extends GameCore

  constructor: ->
    super()
    @ballPosition = [@canvasWidth / 2, @canvasHeight / 2]
    @ball_v = 200 # pixels per second
    @dt = 20
    @dt_in_sec = @dt/1000

    @gamers = {}
    initPos = @canvasHeight / 2 - 40
    @yPositions = [initPos - @racketHeight, initPos + @racketHeight]
    @xOffset = 20
    @ballResetOffset = 50
    @scores = [0, 0]
    @count = 0

    @startLoop()


  addGamer: (sid, socket, side) ->
    @gamers[sid] = {socket: socket, state: 0, side: side, pos: @yPositions[side]}
    @tellSide sid

  tellSide: (sid) ->
    @gamers[sid].socket.emit 'joined', @gamers[sid].side

  sendMove: (sid) ->
    @gamers[sid].socket.emit 'move', {positions: @yPositions, ballPosition: @ballPosition}

  sendMoveAll: ->
    for sid of @gamers
      @sendMove sid

  sendScore: (sid) ->
    @gamers[sid].socket.emit 'score', {scores: @scores}

  sendScoreAll: ->
    for sid of @gamers
      @sendScore sid

  setState: (sid, state) ->
    @gamers[sid].state = state

  placeBall: (side) ->
    @ballPosition[1] = @yPositions[side] + @racketHeight / 2
    if side == 0
      @ballPosition[0] = @ballResetOffset 
      @angle = Math.asin((@yPositions[1] - @yPositions[0]) / @canvasWidth)
    else 
      @ballPosition[0] = @canvasWidth - @ballResetOffset
      @angle = Math.PI + Math.asin((@yPositions[1] - @yPositions[0]) / @canvasWidth)

  detectMove: ->
    for sid, gamer of @gamers
      if gamer.state == -1
        gamer.pos -= @racketStep
      else if gamer.state == 1
        gamer.pos += @racketStep
      gamer.pos = 0 if gamer.pos < 0
      gamer.pos = @canvasHeight - @racketHeight if gamer.pos > @canvasHeight - @racketHeight
      @yPositions[gamer.side] = gamer.pos

  detectBallMove: ->
    ds = @ball_v * @dt_in_sec
    @ballPosition[0] += Math.round( ds * Math.cos(@angle) )
    @ballPosition[1] += Math.round( ds * Math.sin(@angle) )

    if @ballPosition[0] < 0
      @ballPosition[0] = 0
      @angle = Math.PI - @angle
      return
    if @ballPosition[0] > @canvasWidth - @ballSize
      @ballPosition[0] = @canvasWidth - @ballSize
      @angle = Math.PI - @angle
      return
    if @ballPosition[1] < 0
      @ballPosition[1] = 0
      @angle = - @angle
      return
    if @ballPosition[1] > @canvasHeight - @ballSize
      @ballPosition[1] = @canvasHeight - @ballSize
      @angle = - @angle
      return

    ballInRacket = @ballPosition[1] >= @yPositions[0] && @ballPosition[1] <= @yPositions[0] + @racketHeight
    if @ballPosition[0] < @xOffset && ballInRacket
      @ballPosition[0] = @xOffset
      @angle = Math.PI - @angle
      return
    ballInRacket = @ballPosition[1] >= @yPositions[1] && @ballPosition[1] <= @yPositions[1] + @racketHeight
    if @ballPosition[0] > @canvasWidth - @xOffset && ballInRacket
      @ballPosition[0] = @canvasWidth - @xOffset - @ballSize
      @angle = Math.PI - @angle
      return

    @detectScoreUpdate()

  detectScoreUpdate: ->
    if @ballPosition[0] < (@xOffset / 2) or @ballPosition[0] > (@canvasWidth - @xOffset / 2)
      side = -1
      if @ballPosition[0] < (@xOffset / 2)
        @scores[1] += 1
        side = 0
      if @ballPosition[0] > (@canvasWidth - @xOffset / 2)
        @scores[0] += 1
        side = 1
      @placeBall side 
      @sendScoreAll()

  startLoop: ->
    @loop = timers.setInterval =>
      @gameStep()
    , @dt

  endLoop: ->
    timers.clearInterval @loop

  gameStep:  ->
    @detectMove()
    @detectBallMove()
    @sendMoveAll()
    # @sendScoreAll()

  oneQuitted: (sidQuit) ->
    delete @gamers[sidQuit]
    for sid, gamer of @gamers
      gamer.socket.emit('quit', sid) if (sidQuit != sid)

  connect: (socket) ->
    sid = cookie.parse(socket.handshake.headers.cookie)['connect.sid']
    console.log "Have a connection: #{sid} (socket id: #{socket.id})"

    socket.on 'join', (data) =>
      if sid of @gamers
        @tellSide sid
        @sendMove sid
        return
      if @count == 2
        socket.emit 'busy'
        return
      console.log "I can has join: #{sid}"
      @addGamer sid, socket, @count
      @sendMove sid
      @count++
      @sendScore sid
      @startLoop if @count > 0

    socket.on 'state', (data) =>
      console.log "Player #{data.side} moving #{data.state}"
      @setState sid, data.state

    socket.on 'disconnect', =>
      return unless sid of @gamers && @gamers[sid].socket.id == socket.id
      console.log "Disconnecting: #{sid}"
      @oneQuitted sid
      @count--
      @endLoop if @count == 0
