# Description:
#   execute arbitrary shell code
# Commands:
#   hubot exec - executes shell scripts
# Author:
#   Johannes Lauinger <jlauinger@d120.de>

exec = require('child_process').exec;

module.exports = (robot) ->

  robot.respond /exec(?:ute)? (.*)/, (res) ->
    command = "bash -c \""+res.match[1].replace(/"/g,"\\\"")+"\" 2>&1"
    exec command, (error, stdout, stderr) ->
      res.reply "Here you go:"
      res.sendCode stdout
