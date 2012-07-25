stdin = process.openStdin()
stdin.setEncoding 'utf8'

inputCallback = (input) ->
stdin.on 'data', (input) -> inputCallback input

debug = (message) ->
  # console.log message


# Constants
ORBITS = 4

# # Movement variables
fwd_ = "FOREWARD"
in_ = "IN"
out_ = "OUT"


# State
orbits = ((Array() for i in [0...2 * Math.pow 2, o]) for o in [1..ORBITS])

turn = 0
orbitTurn = 0
moveQueue = Array(0)


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

# Utility
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


# Play
playOrbit = ->
  orbit = orbits[orbitTurn]
  mCount = 0
  for rotation in orbit
    debug "Checking rotation: #{(m.turn for m in rotation)}"
    for mass in rotation when mass.turn is turn
      debug "adding #{mass.disp} to move turn"
      if mass.type is "moon"
        mass.queueMove = fwd_
      else
        moveQueue.push(mass)
        mCount += 1
  debug "#{mCount} items to be moved this turn #{turn}"
  if not checkVictory()
    promptForMove()


checkVictory = ->
  ships = {ga:[], eu:[]}
  for orb in orbits
    for rots in orb
      for mass in rots when mass.type is 'fleet'
        switch mass.team
          when 'G' then ships.ga.push(mass)
          when 'E' then ships.eu.push(mass)
  if ships.ga.length is 0
    console.log "Europa Wins"
    true
  else if ships.eu.length is 0
    console.log "Ganymede Wins"
    true
  else
    false


promptForMove = ->
  debug "Prompting move"
  if moveQueue.length is 0
    debug "Move queue is empty for orbit #{orbitTurn}: committing moves"
    debug "Current orbit: #{((m.turn for m in r) for r in orbits[orbitTurn])}"
    commitMoves()
  else
    debug "moveQueue is ready"
    activeMass = moveQueue[0]
    printSpace()
    console.log "Orders for #{activeMass.disp}: "
    debug "Info: turn: #{activeMass.turn} gturn: #{turn}"
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
    debug "Removing from current rotation"
    orbits[mass.orbit][mass.rotation] = (m for m in orbits[mass.orbit][mass.rotation] when m isnt mass)
    newLocation = calculateMove(mass.orbit, mass.rotation, mass.queueMove)
    placeMass(mass, newLocation, moves)
    cleanupMass(mass)


cleanupMass = (mass) ->
  debug "Clearing queueMove, setting lastMove and Turn"
  mass.lastMove = mass.queueMove
  mass.queueMove = undefined
  mass.turn += 1


placeMass = (mass, newLocation, moves) ->
  if survives mass, newLocation, moves
    debug "Setting new location parameters: orbit #{newLocation.orbit} rot #{newLocation.rotation}"
    mass.orbit = newLocation.orbit
    mass.rotation = newLocation.rotation
    debug "Placing mass in new orbit"
    orbits[mass.orbit][mass.rotation].push(mass)
  else
    console.log "#{mass.disp} destroyed"


survives = (mass, newLocation, moves) ->
  nl = newLocation
  enemyMoons = (m for m in orbits[nl.orbit][nl.rotation] when m.type is
    'moon' and m.team isnt mass.team and m.team?)
  enemyShips = (m for m in orbits[nl.orbit][nl.rotation] when m.type is
    'fleet' and m.team isnt mass.team and m not in moves)
  if mass.type is 'moon'
    if enemyShips.length > 0 and mass.team?
      # destroy all enemy ships
      for s in enemyShips
        destroyShip(s)
    true
  else
    if enemyMoons.length > 0
      false
    else
      if enemyShips.length > 0
        if enemyShips.length is 1
          # destroy enemy and survive
          destroyShip(enemyShips[0])
          true
        else
          # destroy one enemy and die
          destroyShip(enemyShips[0])
          false
      else
        true


destroyShip = (ship) ->
  console.log "#{ship.disp} destroyed"
  nu_set = (m for m in orbits[ship.orbit][ship.rotation] when m isnt ship)
  orbits[ship.orbit][ship.rotation] = nu_set


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


# Initiate Game
console.log "Welcome to Orbital"
playOrbit()

