Coordinate = require('./Orbit').Coordiante
Orbit = require('./Orbit').Orbit
Space = require('./Orbit').Space
Mass = require('./Mass').Mass
Moon = require('./Mass').Moon
RelaySatellite = require('./Mass').RelaySatellite
DroneFleet = require('./Mass').DroneFleet
Player = require('./Player').Player

fwd_ = require('./Mass').fwd_
in_ = require('./Mass').in_
out_ = require('./Mass').out_

stdin = process.openStdin()
stdin.setEncoding 'utf8'

debug = (level, message) ->
  lvls = 0:"[ERROR]", 1:"[WARNING]", 2:"[INFO]", 3:"[FLOW]"
  console.log(lvls[level], message) if level <= 0

inputCallback = (input) ->
stdin.on 'data', (input) -> inputCallback input

p1 = new Player('Cpt. Ramses')
p2 = new Player('Toth')

s = new Space(4, p1, p2)

# write a shared callback function for prompt on console
massesToMove = Array()

callCount = 0  # hack for console refactor on 2 player game
playerPrompts = (masses) ->
  callCount += 1
  debug(3, "Prompting player for #{masses.length} masses")
  massesToMove = massesToMove.concat(masses)
  if callCount % 2 is 0
    promptMoves()
  else
    debug(3, "Still waiting for second team (#{callCount})")

promptMoves = () ->
  if massesToMove.length > 0
    printOrbits()
    console.log "Orders for #{massesToMove[0].disp}: "
    inputCallback = (input) ->
      move = input.replace /^\s+|\s+$/g, ""
      moveDic = 'f':fwd_, 'i':in_, 'o':out_
      move = moveDic[move]
      if s.submitMove massesToMove[0].massID, move
        massesToMove = massesToMove[1..]
        promptMoves()
      else
        console.log "#{move} is not a valid move: [o]ut, [i]n, [f]orward"
  else
    debug(3, "No moves to make this turn")

printOrbits = ->
  s.layoutOrbit()
  l = s.orbits.length
  console.log Array(62).join("="), "JUPITER", Array(62).join("=")
  for orbit, orbitIndex in s.orbits
    o = orbit
    oi = orbitIndex
    # Grid math... fun stuff
    orbitDisplaySize = (Math.pow 2, (l + 1 - oi)) - 1
    orbitSteps = orbit.rotations.length - 1
    ods = orbitDisplaySize
    os = orbitSteps
    console.log oi, (Array(ods + 1).join(" ") for j in [0...os]).join("|")

    for rotation, rotationIndex in orbit.rotations
      r = rotation
      ri = rotationIndex
      
      for mass in rotation
        switch mass.queueMove
          when null then mv = ""
          when in_ then mv = "^"
          when fwd_ then mv = ">"
          when out_ then mv = "v"
        console.log "  ", Array((ods + 1) * ri).join(" "), "#{mass.disp}#{mv}"
    console.log Array(132).join('_')

p1.prompt = p2.prompt = playerPrompts
s.playOrbit()
