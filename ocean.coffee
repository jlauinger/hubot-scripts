# Description:
#   Ocean is for shipping software. Everything related to deploying software.
# Commands:
#   hubot deploy project to environment
# Author:
#   Johannes Lauinger <jlauinger@d120.de>

fs = require 'fs'
exec = require('child_process').exec

module.exports = (robot) ->

  configFilename = process.env.HUBOT_OCEAN_CONFIG
  config = JSON.parse fs.readFileSync configFilename, 'utf8'

  robot.respond /deploy ([^ ,]+)(?: to ([^ ,]+))?(?:,? please!?)?/i, (res) ->
    project = res.match[1]
    environment = res.match[2] || 'production'

    context = config.projects[project]

    unless context?
      res.reply "I don't know any project called #{project}, sorry. Did you mistype?"

    context = context[environment]

    unless context?
      res.reply "Project #{project} has no environment #{environment} configured. Did you mistype?"

    deploy context, (err, stdout, stderr, duration) ->
      if err || stderr.length > 0
        res.send "Attention everybody: Deployment of #{project} to #{environment} has failed. Please investigate!"
        res.sendCode stderr
        res.sendCode stdout
      else
        res.send "Deployment of #{project} to #{environment} took #{duration} seconds."
        res.sendCode stdout
        res.reply "Your deployment has finished. Please be aware of any possible bugs or regressions!"


  deploy = (context, cb) ->
    startTime = new Date().getTime()
    command = "ssh #{context.host} \"#{context.command}\""

    console.log command

    exec command, (error, stdout, stderr) ->
      duration = (new Date().getTime() - startTime) / 1000
      cb error, stdout, stderr, duration
