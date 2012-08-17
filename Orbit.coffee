Mass = require('./Mass').Mass
Moon = require('./Mass').Moon
RelaySatellite = require('./Mass').RelaySatellite
DroneFleet = require('./Mass').DroneFleet

fwd_ = require('./Mass').fwd_
in_ = require('./Mass').in_
out_ = require('./Mass').out_

# Potential teams
eu_ = 'E'
ga_ = 'G'
ca_ = 'C'
io_ = 'I'


debug = (level, message) ->
  lvls = 0:"[ERROR]", 1:"[WARNING]", 2:"[INFO]", 3:"[FLOW]"
  console.log(lvls[level], message) if level <= 3


orbitRotationCount = (orbitIndex) ->
  (Math.pow 2, 2 + orbitIndex)


class Coordinate
  constructor: (@o, @r) ->
    if Math.floor(@r) isnt @r   # fractional rotation
      @r = Math.floor @r * orbitRotationCount(@o)

  copy: () ->
    new Coordinate(@o, @r)

  move: (move) ->
    switch move
      when in_
        nuOrb = @o - 1
        nuRot = Math.floor((@r - 1) / 2) + 1
      when out_
        nuOrb = @o + 1
        nuRot = 2 * (@r + 1)
      when fwd_
        nuOrb = @o
        nuRot = @r + 1
      else
        debug(0, "Unknown move: #{move}")
    max = orbitRotationCount(nuOrb)
    if nuRot >= max
      nuRot -= max
    @o = nuOrb
    @r = nuRot
    return @

  relativePosition: ->
    l = orbitRotationCount @o
    nu_r = @r- (Math.floor @r / l) * l
    new Coordinate(@o, nu_r)

  oppositePosition: ->
    l = orbitRotationCount @o
    new Coordinate(@o, @r - l / 2)

  isEclipsed: (coordinate) ->
    op = @oppositePosition()
    if coordinate.o is @o
      coordinate.r is op.r
    else
      if coordinate.o < @o
        d = @o - coordinate.o
        coordinate.r is Math.floor(op.r / Math.pow 2, d)
      else # coordinate.o > @o
        l = orbitRotationCount coordinate.o
        b = Math.pow 2, coordinate.o - @o
        # trust me
        rots = [b * op.r...b * op.r + b].map (y) -> if y < l then y else y - l
        coordinate.r in rots


class Orbit
  constructor: (@index) ->
    debug(2, "Orbit:: Creating new orbit: #{@index}")
    @rotations = (new Array() for i in [0..orbitRotationCount(@index)])
    debug(2, "Orbit:: #{@rotations.length} rotations created")

  add: (mass) ->
    debug(3, "Orbit:: Adding #{mass.disp} to position #{mass.position.r}")
    @rotations[mass.position.r].push(mass)

  checkForBattle: ->
    debug(3, "Orbit #{@index}: checking for battles")
    for r, i in @rotations
      euDrones = (m for m in r when (m instanceof DroneFleet and m.team is eu_))
      gaDrones = (m for m in r when (m instanceof DroneFleet and m.team is ga_))
      drones = (m for m in r when m instanceof DroneFleet)
      if euDrones?.length > 0 and gaDrones?.length > 0
        debug(2, "Battle in orbit #{@index}")
        @battle euDrones, gaDrones
      else
        if r.length > 0
          debug(3, "No Battle in Rotation #{i} with #{drones?.length} drones: eDrones: #{euDrones?.length} gDrones: #{gaDrones?.length}")

  battle: (group1, group2) ->
    coin = Math.random()
    total = group1.length + group2.length
    if group1.length / total < coin # group1 wins
      m.alive = false for m in group2
    else
      m.alive = false for m in group1
    return true



class Space
  constructor: (@orbitCount, @euPlayer, @gaPlayer) ->
    @orbits = (new Orbit(i) for i in [0...@orbitCount])
    @turn = 0
    @orbitTurn = 0
    @masses = Array()
    @placeMoons()
    @placeFleets()
    @placeRelays()
    @layoutOrbit()

  getMassesForPlay: ->
    masses = (m for m in @masses when m.position.o is
      @orbitTurn and m.turn is @turn and m.alive is true)
    debug(3, "Space:getMasses: returning #{masses.length} masses")
    return masses

  playOrbit: ->
    debug(3, "Space:playing orbit")
    @queuedMasses = @getMassesForPlay()
    euMasses = (m for m in @queuedMasses when m.team is
      eu_ and m.activeControl and @inCommunications m)
    gaMasses = (m for m in @queuedMasses when m.team is
      ga_ and m.activeControl and @inCommunications m)
    @euPlayer.prompt(euMasses)
    @gaPlayer.prompt(gaMasses)
    for m in @queuedMasses
      if not m.activeControl
        debug(3, "Setting FWD on #{m.disp}")
        m.queueMove = fwd_
    # TODO drifters
    # check if no prompts needed
    if euMasses.length is 0 and gaMasses.length is 0
      debug(3, "Space:playOrbit: no player moves this turn")
      @commitMoves()

  submitMove: (massID, move) ->
    m = (m for m in @queuedMasses when m.massID is massID)[0]
    if m and @validMove m, move
      m.queueMove = move
      remainingMoves = (m for m in @queuedMasses when m.queueMove is
      null)
      if remainingMoves.length is 0
        @commitMoves()
      else
        debug(3, "Space:submitMove: waiting for #{remainingMoves.length} moves")
      true
    else
      false

  commitMoves: ->
    debug(3, "Space:Commiting Moves...")
    for m in @queuedMasses
      m.makeMove()
    @layoutOrbit()
    for o in @orbits
      o.checkForBattle()
    @destroyMasses()
    @queuedMasses = []
    @orbitTurn += 1
    HALT = false
    if @orbitTurn > @orbitCount
      @orbitTurn = 0
      @turn += 1
      
      # Sanity Check
      straglers = (m for m in @masses when m.turn < @turn)
      if straglers.length > 0
        HALT = true
        debug(0, "Detected straglers: #{straglers.length}")

    if not HALT
      if @isVictory()
        debug(0, "Victory achieved")
      else
        @playOrbit()

  destroyMasses: ->

  inCommunications: (mass) ->
    # TODO 
    # find masses moon
    # check inEclipse on coordinate
    true

  validMove: (mass, move) ->
    if not move in [in_, fwd_, out_]
      false
    else if mass.pastMoves[-1..][0] is in_ and move is out_
      false
    else if mass.pastMoves[-1..][0] is out_ and move is in_
      false
    else if mass.position.o is 0 and move is in_
      false
    else if mass.position.o is @orbitCount - 1 and move is out_
      false
    else
      true
    
  isVictory: ->
    europaFleets = (m for m in @masses when m.team is
      eu_ and m instanceof DroneFleet and m.alive is true)
    ganymedeFleets = (m for m in @masses when m.team is
      ga_ and m instanceof DroneFleet and m.alive is true)
    if europaFleets.length > 0 and ganymedeFleets.length > 0
      false
    else
      if europaFleets.length > 0
        eu_
      else
        ga_

  layoutOrbit: ->
    debug(2, "Space:layoutOrbit: Laying out #{@orbitCount} orbits")
    @orbits = (new Orbit(i) for i in [0...@orbitCount])
    for m in @masses
      if m.position.o not in [0...@orbits.length] 
        debug(0, "Space:layoutOrbit: Bizare orbit on mass: #{m.position.o}")
      if m.alive
        @orbits[m.position.o].add(m)

  placeMoons: ->
    debug(2, "Space:placing moons")
    @masses.push new Moon('Io', 'I', new Coordinate(0, 0), null)
    @masses.push new Moon('Europa', 'E', new Coordinate(1, 0.5), eu_)
    @masses.push new Moon('Ganymede', 'G', new Coordinate(2, 0), ga_)
    @masses.push new Moon('Callisto', 'C', new Coordinate(3, Math.random()), null)

  placeFleets: ->
    debug(2, "Space:placing fleets")
    for i in [1..5]
      @masses.push new DroneFleet("Europa Fleet #{i}", "e#{i}", new Coordinate(1, 0.5), eu_)
      @masses.push new DroneFleet("Ganymede Fleet #{i}", "g#{i}", new Coordinate(2, 0), ga_)

  placeRelays: ->
    debug(2, "Space:placing relays")
    # Eurrpa
    co = new Coordinate(1, 0.5)
    co.r += 3
    @masses.push new RelaySatellite("Europa Relay I", "erI", co.relativePosition(), eu_)
    co.r -= 6
    @masses.push new RelaySatellite("Europa Relay II", "erII", co.relativePosition(), eu_)
    # Ganymede
    co = new Coordinate(2, 0)
    co.r += 5
    @masses.push new RelaySatellite("Ganymede Relay I", "grI", co.relativePosition(), ga_)
    co.r -= 10
    @masses.push new RelaySatellite("Ganymede Relay II", "grII", co.relativePosition(), ga_)


root = exports ? window
root.Space = Space
root.Orbit = Orbit
root.Coordinate = Coordinate
