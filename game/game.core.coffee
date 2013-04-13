class GameCore

  constructor: ->
    @canvasWidth = 780
    @canvasHeight = 440
    @xOffset = 20 # inner side x offset of the racket from the border 

    @racketHeight = 55
    @racketWidth = 10
    @ballSize = 8

    @dirUp = -1
    @dirIdle = 0
    @dirDown = 1

    @gs = [{pos: 10, dir: @dirIdle, updates: []}, {pos: 10, dir: @dirIdle, updates: []}]
    @ballPosition = [@canvasWidth / 2 - @ballSize / 2, @canvasHeight / 2 - @ballSize / 2]

    @angle = (20 + Math.random()*50)*Math.PI/180
    @ballV = 200 # pixels per second
    @racketV = 0.15 # pps

    @updateTime = null
    @dt = 20
    @dtInSec = @dt/1000
    @lastProcessedSeq = -1

  time: ->
    new Date().getTime()

  moveRacket: (dir, dirUpdates, pos, currentTime, lastTime) ->
    for upd in dirUpdates
      continue if upd.t <= lastTime or upd.t > currentTime
      pos = @moveRacketBit pos, dir, (upd.t - lastTime), currentTime, lastTime
      lastTime = upd.t
      dir = upd.dir
      @lastProcessedSeq = upd.seq
    return @moveRacketBit pos, dir, (currentTime - lastTime), currentTime, lastTime

  moveRacketBit: (pos, dir, dt, currentTime, lastTime) ->
    newPos =
      if dir == @dirUp
        pos - @racketV * dt
      else if dir == @dirDown
        pos + @racketV * dt
      else pos
    newPos = 0 if newPos < 0
    newPos = @canvasHeight - @racketHeight if newPos > @canvasHeight - @racketHeight
    newPos

  moveBall: ->
    ds = @ballV * @dtInSec
    @ballPosition[0] += Math.round( ds * Math.cos(@angle) )
    @ballPosition[1] += Math.round( ds * Math.sin(@angle) )
    @checkBallCollision()

  checkBallCollision: ->
    if @ballPosition[1] < 0
      @ballPosition[1] = 0
      @angle = - @angle
      return
    if @ballPosition[1] > @canvasHeight - @ballSize
      @ballPosition[1] = @canvasHeight - @ballSize
      @angle = - @angle
      return
    if @ballPosition[0] <= @xOffset
      if @ballPosition[1] >= @gs[0].pos && @ballPosition[1] <= @gs[0].pos + @racketHeight - @ballSize
        @ballPosition[0] = @xOffset
        @angle = Math.PI - @angle
        return
    if @ballPosition[0] >= @canvasWidth - @xOffset - @ballSize
      if @ballPosition[1] >= @gs[1].pos && @ballPosition[1] <= @gs[1].pos + @racketHeight - @ballSize
        @ballPosition[0] = @canvasWidth - @xOffset - @ballSize
        @angle = Math.PI - @angle
        return


if typeof(module) == 'undefined'
  window.GameCore = GameCore
else
  module.exports = GameCore
