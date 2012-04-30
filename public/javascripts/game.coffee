@canvas_width = 700
@canvas_height = 400
@height = 55
@width = 10

@key_left = 37
@key_up = 38
@key_right = 39
@key_down = 40

@up_pressed = false
@down_pressed = false

@my_y = 10
@dy = 5

# drawing functions

drawBoard = (ctx) ->
  processInputs()
  ctx.clearRect 0, 0, @canvas_width, @canvas_height
  drawRacket ctx, 10, @my_y, "rgb(200,0,0)"
  drawRacket ctx, 680, 10, "rgb(0,0,200)"
  drawBall ctx, 100, 100

drawRacket = (ctx, x, y, color) ->
  ctx.fillStyle = color
  ctx.fillRect x, y, @width, @height

drawBall = (ctx, x, y) ->
  ctx.fillStyle = "rgb(100, 100, 0)"
  ctx.arc x, y, 5, 0, Math.PI*2, true
  ctx.fill()

# Keyboard functions

keyboardDown = (evt) ->
  switch evt.which
    when @key_down then @down_pressed = true; @up_pressed = false
    when @key_up   then @up_pressed = true; @down_pressed = false

keyboardUp = (evt) ->
  switch evt.which
    when @key_down then @down_pressed = false
    when @key_up   then @up_pressed = false

processInputs = ->
  if @up_pressed
    @my_y -= @dy
  else if @down_pressed
    @my_y += @dy

game = ->
  canvas = document.getElementById('game_board_canvas')
  ctx = canvas.getContext '2d'
  drawBoard ctx
  $(window).on 'keydown', keyboardDown
  $(window).on 'keyup', keyboardUp
  setInterval (-> drawBoard ctx), 20

$ ->
  game()
