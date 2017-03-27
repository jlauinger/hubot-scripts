# Description:
#   Some convenient quick checks for FSS folks
#
# Commands:
#   hubot who's working - Display a list of people working on the VMs right now
#   hubot uptimes - Display uptimes of all servers
#   hubot check pings - Probe servers using ping
#
# Author:
#   Johannes Lauinger <jlauinger@d120.de>

vms = process.env.HUBOT_QUICKCHECKS_VMS.split ","

exec = require('child_process').exec;

iterateCommand = (command, msg) ->
  for vm in vms
    command = "ssh #{vm} #{command} 2>&1"
    exec command, (err, stdout, stderr) ->
      msg.sendCode "#{vm}:\n#{stdout}"


module.exports = (robot) ->

  robot.respond /who('s| is) working(( right)? now)?/i, (msg) ->
    iterateCommand "who", msg

  robot.respond /(check |show )?uptimes/i, (msg) ->
    iterateCommand "uptime", msg

  robot.respond /check pings/i, (msg) ->
    for vm in vms
      command = "ping -c 2 #{vm} 2>&1"
      exec command, (err, stdout, stderr) ->
        msg.sendCode "#{vm}:\n#{stdout}"
