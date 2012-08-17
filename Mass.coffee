fwd_ = "FOREWARD"
in_ = "IN"
out_ = "OUT"


class Mass
  constructor: (@name, @disp, @position, @team) ->
    @massID = Mass.count
    Mass.count++
    @turn = 0
    @pastMoves = Array()
    @pastPositions = Array()
    @queueMove = null
    @activeControl = false
    @alive = true

  planMove: ->
    @queueMove = fwd_
    return true

  drift: (maxOrbit) ->
     
  makeMove: () ->
    @pastMoves.push @queueMove
    @pastPositions.push @position.copy()
    @position.move(@queueMove)
    @queueMove = null
    @turn += 1

  @count:0


class Moon extends Mass


class RelaySatellite extends Mass


class DroneFleet extends Mass
  constructor: (@name, @disp, @position, @team) ->
    @lastMove = null
    super
    @activeControl = true

  planMove: (direction) ->
    if direction not in [fwd_, out_, in_]
      return false
    if direction is in_ and @pastMoves[-1..][0] is in_
      return false
    if direction is out_ and @pastMoves[-1..][0] is out_
      return false
    else
      @queueMove = dirction
      return true


root = exports ? window
root.Mass = Mass
root.Moon = Moon
root.RelaySatellite = RelaySatellite
root.DroneFleet = DroneFleet
root.fwd_ = fwd_
root.in_ = in_
root.out_ = out_
