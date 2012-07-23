stdin = process.openStdin()
stdin.setEncoding 'utf8'

inputCallback = (input) ->
stdin.on 'data', (input) -> inputCallback input

ORBITS = 4
orbits = ((Array() for i in [0...2 * Math.pow 2, o]) for o in [1..ORBITS])

# Movement variables
fwd_ = "FOREWARD"
in_ = "IN"
out_ = "OUT"

# Make the moons
ioRot = 0
euRot = Math.round orbits[1].length / 2
gaRot = 0
caRot = Math.ceil Math.random() * orbits[3].length
orbits[0][ioRot].push name: "Io", type: "moon", disp: "I", turn: 0
orbits[1][euRot].push name: "Europa", type: "moon", team: "E", disp: "E", turn: 0
orbits[2][gaRot].push name: "Ganymede", type: "moon", team: "G", disp: "G", turn: 0
orbits[3][caRot].push name: "Callisto", type: "moon", disp: "C", turn: 0

# Make the fleets
for own team, position of {'G':{orbit: 2, rotation: gaRot}, 'E':{orbit: 1, rotation: euRot}}
  for i in [1..5]
    # new fleet
    fleet = {disp: "#{team.toLowerCase()}#{i}", team: team, turn: 0, lastMove: null, type: "fleet", orbit: position.orbit, rotation: position.rotation}
    orbits[position.orbit][position.rotation].push fleet

printSpace = ->
  console.log Array(30).join("="), "JUPITER", Array(30).join("=")
  l = orbits.length
  for orbit, orbitIndex in orbits
    o = orbit
    oi = orbitIndex
    # Grid math... fun stuff
    orbitDisplaySize = (Math.pow 2, (l - oi)) - 1
    orbitSteps = (Math.pow 2, 2 + oi) - 1
    ods = orbitDisplaySize
    os = orbitSteps
    console.log oi, (Array(ods + 1).join(" ") for j in [0..os]).join("|")

    for rotation, rotationIndex in orbit
      r = rotation
      ri = rotationIndex
      
      for mass in rotation
        mv = ""
        if mass?.moveQueue
          mv = {in_:"^", fwd_:">", out_:"v"}[mass.moveQueue]
        console.log "  ", Array((ods + 1) * ri).join(" "), "#{mass.disp}#{mv}"


turn = 0
orbitTurn = 0
moveQueue = Array(0)

playOrbit = ->
  orbit = orbits[orbitTurn]
  for rotation in orbit
    for mass in orbit when mass.turn is turn
      if mass.type is "moon"
        mass.queueMove = fwd_
      else
        moveQueue.push(mass)
  promptForMove()

promptForMove = ->
  if moveQueue.length is 0
    commitMoves()
  else
    activeMass = moveQueue[0]
    console.log "Orders for #{activeMass.disp}: "
    inputCallback = (input) ->
      move = input.replace /^\s+|\s+$/g, ""
      if !legalMove move
        console.log "#{move} is not a valid move: [o]ut, [i]n, [f]oreward"
      else
        move = {"f":fwd_, "i":in_, "o": out_}[move]
        if !isValidMove moveQueue[0], move
          console.log "#{moveQueue[0].disp} is unable to move there"
        else
          moveQueue[0].queueMove = move
          moveQueue = moveQueue[1..]
      printSpace()
      promptForMove()

legalMove = (move) ->
  move in ['f','i','o']

commitMoves = ->
  # loop through all masses with a moveQueue that is not null
  moving = Array(0)
  for o in orbits
    for r in o
      for m in r when m.queueMove
        moving.push(m)


  # make the moves indicated and tally damage
  # clear moveQueues
  # update the current orbit and turn


isValidMove = (fleet, move) ->
  # legal orbit, and no sharp turns
  if fleet.orbit is ORBITS - 1 and move is "OUT"
    false
  else if fleet.orbit is 0 and move is "IN"
    false
  else if fleet.lastMove is "IN" and move is "OUT"
    false
  else if fleet.lastMove is "OUT" and move is "IN"
    false
  else
    true

console.log "Welcome to Orbital"
printSpace()

