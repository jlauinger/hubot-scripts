# Description:
#   cross-post into rooms
# Commands:
#   hubot crosspost to - Send message to another room
# Author:
#   Johannes Lauinger <jlauinger@d120.de>

fs = require 'fs'

module.exports = (robot) ->

  roomsFilename = process.env.HUBOT_ROOMS_CONFIG
  rooms = JSON.parse fs.readFileSync roomsFilename, 'utf8'


  robot.respond /crosspost to ([^ :]*): (.*)/i, (res) ->
    room = rooms[res.match[1]]
    message = res.match[2]

    robot.messageRoom room, message
    res.reply "As you wish!"


  robot.router.post '/hubot/crosspost', (req, res) ->
    data = if req.body.payload? then JSON.parse req.body.payload else req.body
    room = rooms[data.room]

    robot.messageRoom room, data.message
    res.send '200 OK'
