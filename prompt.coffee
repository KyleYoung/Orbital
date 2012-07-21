stdin = process.openStdin()
stdin.setEncoding 'utf8'

inputCallback = null
stdin.on 'data', (input) -> inputCallback input

promptForMove = ->
  console.log "Please enter the move for the next fleet: ([O]ut, [I]n, [F]orward)."
  inputCallback = (input) ->
    promptForMove() if makeMove input.replace /^\s+|\s+$/g, ""

legalMove = (move) ->
  move in ['f','i','o']

makeMove = (move) ->
  if !legalMove move
    console.log "#{move} is not a valid move: o, i, or f."
  else
    {"f":"FORWARD","i":"IN","o":"OUT"}[move]

console.log "Welcome to Orbital"
promptForMove()
