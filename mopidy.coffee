# Description
#   Control the mopidy music server
#
# Dependencies:
#   mopidy
#
# Configuration:
#  HUBOT_MOPIDY_WEBSOCKETURL (eg. ws://localhost:6680/mopidy/ws/)
#
# Commands:
#   hubot set volume <v> - set volume to numeric value 0 to 100
#   hubot volume? - show current volume
#   hubot what's playing? - show current song
#   hubot current playlist? - show current playlist
#   hubot clear playlist - clear the current playlist
#   hubot play <query> - search for a matching song and play it
#   hubot up next <query> - add the song to the front of the playlist
#   hubot queue <query> - add the song to the back of the playlist
#   hubot next track - play next track in playlist
#   hubot mute - set volume to 0
#   hubot unmute - set volume to 100
#   hubot pause music - pause playback
#   hubot resume music - resume playback
#   hubot start shuffle - set shuffle for current playlist
#   hubot stop shuffle - don't shuffle playlist anymore
#   hubot remove track <ids> - remove songs from playlist. Comma-separated list of timeline IDs (use current playlist to find the IDs)
#
# Author:
#   Johannes Lauinger <jlauinger@d120.de>
#   eriley (https://github.com/eriley)


Mopidy = require("mopidy")

mopidy = new Mopidy(webSocketUrl: process.env.HUBOT_MOPIDY_WEBSOCKETURL)

online = false
mopidy.on 'state:online', ->
  online = true
mopidy.on 'state:offline', ->
  online = false


delay = (ms, f) -> setTimeout f, ms


module.exports = (robot) ->

  robot.respond /(?:current )?playlist\??/i, (msg) ->
    if online
      printTracklist = (tracks) ->
        if tracks
          msg.sendCode (tracks.map (t) -> "#{t.tlid}: #{t.track.name} from #{t.track.album.name} by #{t.track.artists[0].name}").join "\n"
        else
          msg.send "Sorry, can't grab current playlist"
      mopidy.tracklist.getTlTracks().then printTracklist, console.error.bind(console)
    else
      msg.send "Mopidy is offline"

  robot.respond /play (.+)/i, (msg) ->
    if online
      q = msg.match[1]
      mopidy.library.search({ any: q }).then (result) ->
        unless result.length && result[0].tracks?.length
          msg.reply "Sorry, can't find any track for #{q}"
          return
        track = result[0].tracks[0]
        mopidy.tracklist.add([track], 1).then () ->
          mopidy.tracklist.getTlTracks().then (tlTracks) ->
            mopidy.playback.play tlTracks[1]
            msg.send "Now playing #{track.name} from #{track.album.name} by #{track.artists[0].name}"
    else
      msg.send "Mopidy is offline"

  robot.respond /up next (.+)/i, (msg) ->
    if online
      q = msg.match[1]
      mopidy.library.search({ any: q }).then (result) ->
        unless result.length && result[0].tracks?.length
          msg.reply "Sorry, can't find any track for #{q}"
          return
        track = result[0].tracks[0]
        mopidy.tracklist.add([track], 1).then () ->
          msg.send "Next song up is #{track.name} from #{track.album.name} by #{track.artists[0].name}"
    else
      msg.send "Mopidy is offline"

  robot.respond /queue(?: up)? (.+)/i, (msg) ->
    if online
      q = msg.match[1]
      mopidy.library.search({ any: q }).then (result) ->
        unless result.length && result[0].tracks?.length
          msg.reply "Sorry, can't find any track for #{q}"
          return
        track = result[0].tracks[0]
        mopidy.tracklist.add([track]).then () ->
          msg.send "I've added #{track.name} from #{track.album.name} by #{track.artists[0].name} to the playlist."
    else
      msg.send "Mopidy is offline"

  robot.respond /clear playlist!?/i, (msg) ->
    if online
      mopidy.tracklist.clear().then (result) ->
        msg.send "Playlist is now empty and sad :("
    else
      msg.send "Mopidy is offline"

  robot.respond /remove track ([\d,]+)/i, (msg) ->
    ids = msg.match[1].split(',').map (id) -> parseInt(id)
    if online
      mopidy.tracklist.remove({ tlid: ids }).then (tracks) ->
        if tracks
          msg.send "I've removed these tracks from the playlist:"
          msg.sendCode (tracks.map (t) -> "#{t.track.name} from #{t.track.album.name} by #{t.track.artists[0].name}").join "\n"
        else
          msg.send "Sorry, didn't find any matching tracks on the playlist to remove."
    else
      msg.send "Mopidy is offline"

  robot.respond /(?:set )?volume(?: to)? (\d+)/i, (message) ->
    newVolume = parseInt(message.match[1])
    if online
      console.log mopidy.playback
      mopidy.playback.setVolume(newVolume)
      message.send("Setting volume to #{newVolume}...")
    else
      message.send('Mopidy is offline')

  robot.respond /volume\??/i, (message) ->
    if online
      printCurrentVolume = (volume) ->
        if volume
          message.send("The Current volume is #{volume}")
        else
          message.send("Sorry, can't grab current volume")
    else
      message.send('Mopidy is offline')
    mopidy.playback.getVolume().then printCurrentVolume, console.error.bind(console)

  robot.respond /what'?s playing\??/i, (message) ->
    if online
      printCurrentTrack = (track) ->
        if track
          message.send("Currently playing: #{track.name} by #{track.artists[0].name} from #{track.album.name}")
        else
          message.send("No track is playing")
    else
      message.send('Mopidy is offline')
    mopidy.playback.getCurrentTrack().then printCurrentTrack, console.error.bind(console)

  robot.respond /next track/i, (message) ->
    if online
      mopidy.playback.next().then (result) ->
        delay 1000, ->
          mopidy.playback.getCurrentTrack().then (track) ->
            if track
              message.send("Now playing: #{track.name} by #{track.artists[0].name} from #{track.album.name}")
            else
              message.send("No track is playing")
    else
      message.send('Mopidy is offline')

  robot.respond /mute/i, (message) ->
    if online
      mopidy.playback.setMute(true)
      message.send('Playback muted')
    else
      message.send('Mopidy is offline')

  robot.respond /unmute/i, (message) ->
    if online
      mopidy.playback.setMute(false)
      message.send('Playback unmuted')
    else
      message.send('Mopidy is offline')

  robot.respond /pause music/i, (message) ->
    if online
      mopidy.playback.pause()
      message.send('Music paused')
    else
      message.send('Mopidy is offline')

  robot.respond /resume music/i, (message) ->
    if online
      mopidy.playback.resume()
      message.send('Music resumed')
    else
      message.send('Mopidy is offline')

  robot.respond /shuffle music/i, (message) ->
    if online
      mopidy.tracklist.setRandom(true)
      message.send('Now shuffling')
    else
      message.send('Mopidy is offline')

  robot.respond /stop shuffle/i, (message) ->
    if online
      mopidy.tracklist.setRandom(false)
      message.send('Shuffling has been stopped')
    else
      message.send('Mopidy is offline')

