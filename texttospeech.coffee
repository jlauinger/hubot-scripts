# Description
#   Provide basic Text-to-Speech functionality for Mopidy
#
# Dependencies:
#   arraybuffer-to-buffer
#   mespeak
#   mpd
#
# Configuration:
#  HUBOT_MOPIDY_WEBSOCKETURL (eg. ws://localhost:6680/mopidy/ws/)
#
# Commands:
#   hubot say <text> - say something with text to speech
#
# Author:
#   Johannes Lauinger <jlauinger@d120.de>

meSpeak = require 'mespeak'
arrayBufferToBuffer = require 'arraybuffer-to-buffer'
mpd = require 'mpd'

cmd = mpd.cmd

meSpeak.loadConfig require 'mespeak/src/mespeak_config.json'
meSpeak.loadVoice require 'mespeak/voices/en/en-us.json'

config =
  host: process.env.HUBOT_TTS_MPD_HOST
  port: process.env.HUBOT_TTS_MPD_PORT

client = mpd.connect config

host = process.env.HUBOT_HOST_IP
port = process.env.EXPRESS_PORT


module.exports = (robot) ->

  robot.respond /say (.+)/i, (msg) ->
    text = encodeURIComponent msg.match[1]
    url = "http://#{host}:#{port}/hubot/tts/speak/#{text}"
    addCommand = cmd "addid #{url} 0", []
    client.sendCommand addCommand, (err, m) ->
      playCommand = cmd "play 0", []
      client.sendCommand playCommand, (err, m) ->
        msg.reply "Enjoy!"

  robot.router.get '/hubot/tts/speak/:text', (req, res) ->
    audio = meSpeak.speak req.params.text, { rawdata: 'array' }

    # Bit "adjustments" - see:
    #  - https://de.wikipedia.org/wiki/RIFF_WAVE
    #  - http://soundfile.sapp.org/doc/WaveFormat/
    #
    #     22   24   26   28   30   32   34   36   38   40   42   44
    # ---+----+---------+---------+----+----+---------+---------+--------------
    #    | Ch | SamplRa | ByteRat | BA | bps| SubChID | SubChSz | Data...
    # ---+----+---------+---------+----+----+---------+---------+--------------

    size = (audio.length - 44) * 4
    buf = Array size

    for i in [0..43]
      buf[i] = audio[i]

    buf[22] = 0x02  # NumChannels (little) [22-23]: 2
    buf[24] = 0x44  # SamplingRate (little) [24-27]: 44.1 kHz
    buf[25] = 0xAC  # SamplingRate (little) [24-27]: 44.1 kHz
    buf[28] = 0x10  # ByteRate (little) [28-31]: 44.1 * 4
    buf[29] = 0xB1  # ByteRate (little) [28-31]: 44.1 * 4
    buf[30] = 0x02  # ByteRate (little) [28-31]: 44.1 * 4
    buf[32] = 0x04  # BlockAlign (little) [32-33]: 2*(16+7)//8

    subChunkSize = 4 * (audio[40] + audio[41]*Math.pow(2,8) + audio[42]*Math.pow(2,16) + audio[43]*Math.pow(2,24))
    buf[40] = (subChunkSize & 0x000000ff) >> 0   # SubChunkSize (little) [40-43]
    buf[41] = (subChunkSize & 0x0000ff00) >> 8   # SubChunkSize (little) [40-43]
    buf[42] = (subChunkSize & 0x00ff0000) >> 16  # SubChunkSize (little) [40-43]
    buf[43] = (subChunkSize & 0xff000000) >> 24  # SubChunkSize (little) [40-43]

    for i in [44..size-1] by 2
      if i % 4 == 0
        ptr = Math.floor((i - 44) / 4) + 44                         # copy samples
        buf[i] = ((audio[ptr] >> 1) | (audio[ptr+1] & 0x80)) - 127  # convert to signed
        buf[i+1] = (audio[ptr+1] >> 1) - 127
      else
        ptr1 = Math.floor((i - 44) / 4) + 44 - 2                    # extract previous and next sample
        ptr2 = Math.floor((i - 44) / 4) + 44 + 2
        sample1 = audio[ptr1] + audio[ptr1]*256
        sample2 = audio[ptr2] + audio[ptr2]*256
        sample = Math.floor((sample1 + sample2) / 2)                # calculate average as interpolated sample
        byte1 = (sample & 0x00ff) >> 0                              # split bytes
        byte2 = (sample & 0xff00) >> 8
        buf[i]   = ((byte1 >> 1) | (byte2 & 0x80)) - 127            # convert to signed
        buf[i+1] = (byte2 >> 1) - 127

    res.set { 'Content-Type': 'audio/wav' }
    res.send new Buffer buf
    res.end()

#  robot.router.get '/hubot/tts/speak/:text', (req, res) ->
#    config =
#      text: 'hallo'
#      file: 'tmp/tts.mp3'
#      language: 'de'
#      encoding: 'UTF-8'
#    googleSpeech.TTS config, () ->
#      res.download 'tmp/tts.mp3'
