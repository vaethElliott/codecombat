Bus = require './Bus'
{me} = require 'core/auth'
LevelSession = require 'models/LevelSession'
utils = require 'core/utils'
GameUIState = require 'models/GameUIState'
# firebase = require('firebase/app')
# require('firebase/database')
 
module.exports = class GameDevLevelBus extends Bus
  @get: (sessionID) ->
    docName = "play/game-dev-level/#{sessionID}"
    return @getByDocName docName
  @getByDocName: (docName) ->
    return Bus.getFromCache(docName) or new GameDevLevelBus docName
  
  subscriptions:
    'playback:real-time-playback-started': 'onRealTimePlaybackStarted'
    'playback:real-time-playback-ended': 'onRealTimePlaybackEnded'
    'god:new-world-created': 'onNewWorldCreated'
  
  constructor: ->
    super(arguments...)
  
  setGameUIState: (gameUIState, god) ->
    @god = god
    return if @gameUIState is gameUIState
    @gameUIState = gameUIState
    @realTimeInputEvents = @gameUIState.get 'realTimeInputEvents'
    @listenTo @realTimeInputEvents, 'add', @onRealTimeInputEventsChanged
    @listenTo @realTimeInputEvents, 'reset', @onRealTimeInputEventsReset
  
  init: ->
    # super()
    # @firePlaybackRef = @fireRef.child('playback')
    # @firePlaybackRef.on 'value', @onFirePlaybackChanged
    #@firePlaybackRealTimeInputEventsRef = @firePlaybackRef.child('realTimeInputEvents')
    @join()
    @socket.on('state', (data) =>
      for e in data 
        if e.id != me.id
          nothing = 1
          e.gameUIState = JSON.parse(e.gameUIState)
          state = new GameUIState()
          state.set('selected', e.gameUIState.selected)
          state.set('canDragCamera', e.gameUIState.canDragCamera)
          state.get('realTimeInputEvents').add(e.gameUIState.realTimeInputEvents)
          @addState({id: e.id, gameUIState: state})
          # console.log(e.id)    # TODO: move this id's player to this state, if state is null, then move to initial state
          # console.log(e.state)
    );

  addState: (state) =>
    @god.addGameUIState(state)
  
  onMeSynced: =>
    # super()
    console.log("onMeSynced")
  
  join: ->
    # super()
    console.log("emitting")
    data = {id: me.id, gameUIState: JSON.stringify(@gameUIState)}
    @socket.emit('new player', data);
  
  connect: ->
    @socket = io()
    console.log(@socket)
    @init()
  
  disconnect: ->
    console.log("disconect")
    # super()
    # @firePlaybackRef?.off()
    # @firePlaybackRef = null
  
  onRealTimePlaybackStarted: (e) ->
    console.log("started")
    # return if @playing
    # @playing = true
    # return if @playback?.startPlayer is me.id and @playbackIsCurrent()
    # elapsed = new Date().getTime() - @playback?.startDate ? 0
    # console.log "It's been #{elapsed} since playback was started by #{if @playback?.startPlayer is me.id then 'me' else @playback?.startPlayer}, so we're starting playback!"
    # @playback = playing: true, startDate: new Date().getTime(), startPlayer: me.id, realTimeInputEvents: []
    # playback = _.clone @playback
    # # playback.startDate = firebase.database.ServerValue.TIMESTAMP
    # @firePlaybackRef.set playback
  
  onRealTimePlaybackEnded: (e) ->
    console.log("ended")
    # return unless @playing
    # @playing = false
    # if @playback?.startPlayer is me.id
    #   @playback = playing: false
    #   console.log "Playback has ended, stopping it right up."
    #   @firePlaybackRef.set @playback
    # else
      # console.log "Playback has ended, so #{@playback?.startPlayer} should stop that up."
  
  onFirePlaybackChanged: (snapshot) =>
    console.log("fire play back changed")
    # newPlayback = snapshot.val()
    # return if newPlayback.playing is false and @playing  # Someone else stopped playing, but we haven't yet.
    # @playback = newPlayback
    # return unless @playback
    # console.log 'Playback has been updated:', @playback, '-- is me?', @playback.startPlayer is me.id, 'is current?', @playbackIsCurrent(), 'after', new Date().getTime() - @playback?.startDate ? 0
    # if not @playing and @playback.playing and @playback.startPlayer isnt me.id and @playbackIsCurrent()
    #   console.log '  We should start too, yo!'
    #   Backbone.Mediator.publish 'bus:multiplayer-level-start', playback: @playback, bus: @
    # existingEvents = @formatRealTimeInputEvents()
    # if @playing
    #   for key, event of @playback.realTimeInputEvents ? []
    #     if _.find existingEvents, event
    #       console.log "Found existing network input event:", event, event.type, event.keyCode, 'at', event.time
    #     else
    #       console.log 'Got new networked input event:', event, event.type, event.keyCode, 'at', event.time
    #       @realTimeInputEvents.add event
  
  playbackIsCurrent: ->
    Math.abs(@playback.startDate - new Date().getTime()) < 2000
  
  onRealTimeInputEventsReset: (e) ->
    console.log("reset")
    currentEvents = @formatRealTimeInputEvents()
    console.log(currentEvents)

  onRealTimeInputEventsChanged: (e) ->
    console.log("changed")
    # # TODO: differentiate between reset and new event handlers
    # console.log 'yo yo yo yo yo got new real time input event', e
    # currentEvents = @formatRealTimeInputEvents()
    @socket.emit("input changed", {id: me.id, gameUIState: JSON.stringify(@gameUIState)})
    # if not currentEvents.length and (@playback.realTimeInputEvents ? []).length
    #   console.log "  Clearing events."
    #   @playback.realTimeInputEvents = currentEvents
    #   @firePlaybackRef.child('realTimeInputEvents').set @playback.realTimeInputEvents
    # else if currentEvents.length and not @playback.realTimeInputEvents
    #   @playback.realTimeInputEvents = currentEvents
    #   @firePlaybackRef.child('realTimeInputEvents').set @playback.realTimeInputEvents
    # else
    #   for event in currentEvents
    #     unless _.find @playback.realTimeInputEvents, event
    #       console.log "  Adding new event:", event.type, event.keyCode, event.time, event
    #       key = @firePlaybackRef.child('realTimeInputEvents').push event
    #       @playback.realTimeInputEvents[key] = event
    # #@playback.realTimeInputEvents = @formatRealTimeInputEvents()
    # #console.log @playback.realTimeInputEvents
    # #@firePlaybackRef.child('realTimeInputEvents').push @playback.realTimeInputEvents
  
  formatRealTimeInputEvents: ->
    formattedEvents = []
    console.log(@realTimeInputEvents)
    for event in @realTimeInputEvents.models
      formattedEvent = event.attributes
      formattedEvents.push formattedEvent
    formattedEvents
  
  onNewWorldCreated: (e) ->
    return unless @onPoint()
    console.log 'on New World Created'
    return
    # Record the flag history.
    state = @session.get('state')
    flagHistory = (flag for flag in e.world.flagHistory when flag.source isnt 'code')
    return if _.isEqual state.flagHistory, flagHistory
    state.flagHistory = flagHistory
    @changedSessionProperties.state = true
    @session.set('state', state)
    @saveSession()
  
  onPlayerJoined: (snapshot) =>
    super(arguments...)
    return unless @onPoint()
    # TODO: anything?
    console.log(@players)
    return
    players = @session.get('players')
    players ?= {}
    player = snapshot.val()
    return if players[player.id]?
    players[player.id] = {}
    @session.set('players', players)
    @changedSessionProperties.players = true
    @saveSession()
  
  onChatAdded: (snapshot) =>
    super(arguments...)
    # TODO: anything?
    return
    chat = @session.get('chat')
    chat ?= []
    message = snapshot.val()
    return if message.system
    chat.push(message)
    chat = chat[chat.length-50...] if chat.length > 50
    @session.set('chat', chat)
    @changedSessionProperties.chat = true
    @saveSession()
  
  destroy: ->
    @socket.emit('disconnect player', me.id);
    @disconnect()