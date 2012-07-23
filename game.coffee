stdin = process.openStdin()
stdin.setEncoding 'utf8'

inputCallback = (input) ->
stdin.on 'data', (input) -> inputCallback input

debug = (message) ->
  # console.log message

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
orbits[0][ioRot].push name: "Io", type: "moon", disp: "I", turn: 0, orbit:0, rotation:ioRot
orbits[1][euRot].push name: "Europa", type: "moon", team: "E", disp: "E", turn: 0, orbit:1, rotation:euRot
orbits[2][gaRot].push name: "Ganymede", type: "moon", team: "G", disp: "G", turn: 0, orbit:2, rotation:gaRot
orbits[3][caRot].push name: "Callisto", type: "moon", disp: "C", turn: 0, orbit:3, rotation:caRot

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
        switch mass.queueMove
          when undefined then mv = ""
          when in_ then mv = "^"
          when fwd_ then mv = ">"
          when out_ then mv = "v"
        console.log "  ", Array((ods + 1) * ri).join(" "), "#{mass.disp}#{mv}"
    console.log Array(67).join('_')


turn = 0
orbitTurn = 0
moveQueue = Array(0)

playOrbit = ->
  orbit = orbits[orbitTurn]
  for rotation in orbit
    for mass in rotation when mass.turn is turn
      if mass.type is "moon"
        mass.queueMove = fwd_
      else
        moveQueue.push(mass)
  promptForMove()

promptForMove = ->
  if moveQueue.length is 0
    debug "Move queue is empty: committing moves"
    commitMoves()
  else
    debug "moveQueue is ready"
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
  debug "commitMoves. "
  moving = pendingMoves()
  makeMoves(moving)
  debug "commitMoves. updating the current orbit and turn"
  if orbitTurn is ORBITS - 1
    orbitTurn = 0
    turn += 1
  else
    orbitTurn += 1
  debug "commitMoves. Calling next orbit #{orbitTurn}"
  playOrbit()

pendingMoves = ->
  moving = Array()
  for orbit in orbits
    for rotation in orbit
      for mass in rotation when mass.queueMove?
        moving.push(mass)
  moving

makeMoves = (moves) ->
  for mass in moves
    debug "Making move for #{mass.disp}"
    # remove from current orbit/rotation
    debug "Removing from current rotation"
    location = orbits[mass.orbit][mass.rotation].indexOf(mass)
    debug "Location of mass: #{location}"
    #orbits[mass.orbit][mass.rotation] = orbits[mass.orbit][mass.rotation].splice(location, 1)
    orbits[mass.orbit][mass.rotation] = (m for m in orbits[mass.orbit][mass.rotation] when m isnt mass)
    newLocation = calculateMove(mass.orbit, mass.rotation, mass.queueMove)
    # place in new orbit/rotation
    debug "Setting new location parameters: orbit #{newLocation.orbit} rot #{newLocation.rotation}"
    mass.orbit = newLocation.orbit
    mass.rotation = newLocation.rotation
    debug "Placing mass in new orbit"
    orbits[mass.orbit][mass.rotation].push(mass)
    # clear queue move, and set lastMove and turn
    debug "Clearing queueMove, setting lastMove and Turn"
    mass.lastMove = mass.queueMove
    mass.queueMove = undefined
    mass.turn += 1

calculateMove = (orbit, rotation, move) ->
  debug "Calculating movement from orbit #{orbit}/#{rotation} #{move}"
  switch move
    when in_
      new_orbit = orbit - 1
      new_rotation = Math.floor((rotation - 1) / 2) + 1
    when out_
      new_orbit = orbit + 1
      new_rotation = 2 * rotation + 2
    when fwd_
      new_orbit = orbit
      new_rotation = rotation + 1
    else
      console.log "[ERROR] Unknown move: #{move}"
  # check for complete rotation
  orbit_max_rotation = (Math.pow 2, 2 + new_orbit)
  if new_rotation is orbit_max_rotation
    new_rotation -= orbit_max_rotation
  orbit:new_orbit, rotation:new_rotation
  
isValidMove = (fleet, move) ->
  # legal orbit, and no sharp turns
  if fleet.orbit is ORBITS - 1 and move is out_
    false
  else if fleet.orbit is 0 and move is in_
    false
  else if fleet.lastMove is in_ and move is out_
    false
  else if fleet.lastMove is out_ and move is in_
    false
  else
    true

console.log "Welcome to Orbital"
playOrbit()
