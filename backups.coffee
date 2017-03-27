# Description:
#   monitor backups of site infrastucture
# Commands:
#   hubot sup backups - show current backup status
# Author:
#   Johannes Lauinger <jlauinger@d120.de>

fs = require 'fs'
exec = require('child_process').exec;

module.exports = (robot) ->

  roomsFilename = process.env.HUBOT_ROOMS_CONFIG
  rooms = JSON.parse fs.readFileSync roomsFilename, 'utf8'
  room = rooms["test"]


  robot.respond /(?:what)?\'?s ?up backups?\??/i, (res) ->
    res.reply "chill, I think it's ok"


  robot.router.post '/hubot/backups/status', (req, res) ->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body

    robot.messageRoom room, "This just in: Backup #{data.name} was successful and took #{data.time} seconds."
    res.send '200 OK'
