class Player
  constructor: (@name) ->

  prompt: -> # override method for player communication


root = exports ? window
root.Player = Player
