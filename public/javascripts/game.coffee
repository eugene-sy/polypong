window.Game = class Game

  constructor: ->
    # Vars
    @up_pressed = false
    @down_pressed = false
    @y_positions = [10, 10]
    @side = 0
    @enemy_side = 1

    # Constants
    @canvas_width = 780
    @canvas_height = 440
    @racket_height = 55
    @racket_width = 10

    @dy = 5

    @key_left  = 37
    @key_up    = 38
    @key_right = 39
    @key_down  = 40
    @key_space = 32

    @dir_up = -1
    @dir_idle = 0
    @dir_down = 1
    @players_start_pos = [[10, 80], [760, @canvas_height - 80 - @racket_height]]
    @players_colors = ['rgb(255,255,255)', 'rgb(255,255,255)']


  # Drawing functions

  drawRacket: (x, y, color) ->
    @ctx.fillStyle = color
    @ctx.fillRect x, y, @racket_width, @racket_height

  drawBall: (x, y) ->
    @ctx.fillStyle = "rgb(200, 200, 200)"
    @ctx.fillRect x, y, 8, 8

  drawBoard: ->
    @processInputs()
    @ctx.clearRect 0, 0, @canvas_width, @canvas_height
    @ctx.fillStyle = "rgb(200, 200, 200)"
    @ctx.fillRect 389, 5, 1, 430
    @drawRacket @players_start_pos[@side][0], @y_positions[@side], @players_colors[@side]
    @drawRacket @players_start_pos[@enemy_side][0], @y_positions[@enemy_side], @players_colors[@enemy_side]
    @drawBall 100, 100


  # Keyboard functions

  keyboardDown: (evt) ->
    switch evt.which
      when @key_down then @down_pressed = true; @up_pressed = false; @sendState @dir_down
      when @key_up   then @up_pressed = true; @down_pressed = false; @sendState @dir_up

  keyboardUp: (evt) ->
    switch evt.which
      when @key_down then @down_pressed = false; @sendState @dir_idle unless @up_pressed
      when @key_up   then @up_pressed = false; @sendState @dir_idle unless @down_pressed

  processInputs: ->
#    if @up_pressed
#      @y_positions -= @dy
#      @players_states[@side] = -1
#    else if @down_pressed
#      @y_positions += @dy
#      @players_states[@side] = 1
#    else
#      @players_states[@side] = 0
#    console.log @players_states[@side]

  sendState: (dir) ->
    @socket.emit 'state', {side: @side, state: dir}

  # Game control functions

  startGame: ->
    canvas = document.getElementById('game_board_canvas')
    @ctx = canvas.getContext '2d'
    @drawBoard()
    self = @
    setInterval (-> self.drawBoard()), 500

  start: (socket) ->
    self = @
    @socket = socket

    socket.on 'connect', ->
      console.log "Socket opened, Master!"

    socket.on 'joined', (side) ->
      self.side = side
      self.enemy_side = if side == 0 then 1 else 0
      self.y_position = self.players_start_pos[self.side][1]
      # Can't move while not joined
      $(window).on 'keydown', (e) -> self.keyboardDown e
      $(window).on 'keyup', (e) -> self.keyboardUp e

    socket.on 'move', (data) ->
      self.y_positions[self.side] = data.positions[self.side]
      self.y_positions[self.enemy_side] = data.positions[self.enemy_side]
      console.log "#{self.y_positions[self.side]}, #{self.y_positions[self.enemy_side]}"
      self.down_pressed = false
      self.up_pressed = false
      self.players_states = [0, 0]
      self.drawBoard()

    socket.on 'busy', (data) ->

    socket.emit 'join'



    @startGame()
