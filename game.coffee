ORBITS = 4
orbits = ((Array() for i in [0...2 * Math.pow 2, o]) for o in [1..ORBITS])

# Make the moons
ioRot = 0
euRot = Math.round orbits[1].length / 2
gaRot = 0
caRot = Math.ceil Math.random() * orbits[3].length
orbits[0][ioRot].push name: "Io", type: "moon", disp: "I"
orbits[1][euRot].push name: "Europa", type: "moon", team: "E", disp: "E"
orbits[2][gaRot].push name: "Ganymede", type: "moon", team: "G", disp: "G"
orbits[3][caRot].push name: "Callisto", type: "moon", disp: "C"

# Make the fleets
for own team, position of {'G':{orbit: 2, rotation: gaRot}, 'E':{orbit: 1, rotation: euRot}}
  for i in [1..5]
    # new fleet
    fleet = {disp: "#{team.toLowerCase()}#{i}", team: team, turn: 0, lastMove: null, type: "fleet", orbit: position.orbit, rotation: position.rotation}
    orbits[position.orbit][position.rotation].push fleet

printSpace = ->
  console.log Array(36).join("="), "JUPITER", Array(37).join("=")
  l = orbits.length
  for orbit, orbitIndex in orbits
    o = orbit
    oi = orbitIndex
    # Grid math... fun stuff
    orbitDisplaySize = (Math.pow 2, (l - oi)) - 1
    orbitSteps = (Math.pow 2, 2 + oi) - 1
    ods = orbitDisplaySize
    os = orbitSteps
    console.log oi, (Array(ods).join(" ") for j in [0..os]).join("|")

    for rotation, rotationIndex in orbit
      r = rotation
      ri = rotationIndex
      
      for mass in rotation
        console.log Array((ods + 1) * ri).join(" "), mass.disp

turn = 0

playMove = (orbits, fleet, move) ->
  if isValidMove(orbits, fleet, move)
    # TODO make the play
    switch move
      when "IN" then 
      when "OUT" then
      when "FORWARD" then
  else
    console.log "Invalid move"

isValidMove = (orbits, fleet, move) ->
  # legal orbit, and no sharp turns
  if fleet.orbit is orbits.length - 1 and move is "OUT"
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

