class GameCore

  constructor: ->
    @canvasWidth = 780
    @canvasHeight = 440

    @racketHeight = 55
    @racketWidth = 10
    @racketStep = 10

    @ballSize = 8

    @angle = (20 + Math.random()*50)*Math.PI/180


if typeof(module) == 'undefined'
  window.GameCore = GameCore
else
  module.exports = GameCore
