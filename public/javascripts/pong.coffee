window.Game = class Game

  constructor: ->
    # Vars
    @up_pressed = false
    @down_pressed = false
    @y_positions = [10, 10]
    @side = 0
    @enemy_side = 1
    @ball_pos = [100, 100]
    @angle = (20 + Math.random()*50)*Math.PI/180

    # Constants
    @canvas_width = 780
    @canvas_height = 440
    @racket_height = 55
    @racket_width = 10
    @ball_size = 8

    @dy = 5
    @dt = 20
    @dt_in_sec = @dt/1000
    @ball_v = 200 # pixels per second

    @key_left  = 37
    @key_up    = 38
    @key_right = 39
    @key_down  = 40
    @key_space = 32

    @dir_up = -1
    @dir_idle = 0
    @dir_down = 1
    @players_start_pos = [[10, 80], [760, @canvas_height - 80 - @racket_height]]
    @racket_color = '#fff'


  # Drawing functions

  drawRacket: (x, y, color) ->
    @ctx.fillStyle = color
    @ctx.fillRect x, y, @racket_width, @racket_height

  drawBall: (x, y) ->
    @ctx.fillStyle = "rgb(200, 200, 200)"
    @ctx.fillRect x, y, @ball_size, @ball_size

  drawBoard: ->
    @ctx.clearRect 0, 0, @canvas_width, @canvas_height
    @ctx.fillStyle = "rgb(200, 200, 200)"
    @ctx.fillRect 389, 5, 1, 430
    @drawRacket @players_start_pos[@side][0], @y_positions[@side], @racket_color
    @drawRacket @players_start_pos[@enemy_side][0], @y_positions[@enemy_side], @racket_color
    @drawBall @ball_pos[0], @ball_pos[1]


  # Game logic

  gameLoop: ->
    @updateState()
    @drawBoard()

  updateState: ->
    @updateBall()

  updateBall: ->
    ds = @ball_v * @dt_in_sec
    @ball_pos[0] += ds * Math.cos(@angle)
    @ball_pos[1] += ds * Math.sin(@angle)

    if @ball_pos[0] < 0
      @ball_pos[0] = 0
      @angle = Math.PI - @angle
      return
    if @ball_pos[0] > @canvas_width - @ball_size
      @ball_pos[0] = @canvas_width - @ball_size
      @angle = Math.PI - @angle
      return
    if @ball_pos[1] < 0
      @ball_pos[1] = 0
      @angle = - @angle
      return
    if @ball_pos[1] > @canvas_height - @ball_size
      @ball_pos[1] = @canvas_height - @ball_size
      @angle = - @angle
      return

    ball_in_racket = @ball_pos[1] >= @y_positions[0] && @ball_pos[1] <= @y_positions[0] + @racket_height
    if @ball_pos[0] < 20 && ball_in_racket
      @ball_pos[0] = 20
      @angle = Math.PI - @angle
      return
    ball_in_racket = @ball_pos[1] >= @y_positions[1] && @ball_pos[1] <= @y_positions[1] + @racket_height
    if @ball_pos[0] > @canvas_width - 20 && ball_in_racket
      @ball_pos[0] = @canvas_width - 20 - @ball_size
      @angle = Math.PI - @angle
      return


  # Keyboard functions

  keyboardDown: (evt) ->
    switch evt.which
      when @key_down then @down_pressed = true; @up_pressed = false; @sendState @dir_down
      when @key_up   then @up_pressed = true; @down_pressed = false; @sendState @dir_up

  keyboardUp: (evt) ->
    switch evt.which
      when @key_down then @down_pressed = false; @sendState @dir_idle unless @up_pressed
      when @key_up   then @up_pressed = false; @sendState @dir_idle unless @down_pressed

  sendState: (dir) ->
    @socket.emit 'state', {side: @side, state: dir}


  # Game control functions

  startGame: ->
    canvas = document.getElementById('game_board_canvas')
    @ctx = canvas.getContext '2d'
    self = @
    setInterval (-> self.gameLoop()), @dt

  start: (socket) ->
    self = @
    @socket = socket

    socket.on 'connect', ->
      console.log "Socket opened, Master!"

    socket.on 'joined', (side) ->
      self.side = side
      self.enemy_side = if side == 0 then 1 else 0
      # Can't move while not joined
      $(window).on 'keydown', (e) -> self.keyboardDown e
      $(window).on 'keyup', (e) -> self.keyboardUp e

    socket.on 'move', (data) ->
      self.y_positions = data.positions
      console.log "#{self.y_positions[self.side]}, #{self.y_positions[self.enemy_side]}"

    socket.on 'busy', (data) ->

    socket.emit 'join'


    @startGame()
