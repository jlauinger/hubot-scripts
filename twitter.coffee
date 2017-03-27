# Description:
#   Create and delete tweets on Twitter.
#
# Dependencies:
#   "twit": "1.1.x"
#
# Configuration:
#   HUBOT_TWITTER_ACCOUNTS - comma-separated accounts list, without @. First is default-account.
#   HUBOT_TWITTER_<ACC>_CONSUMER_KEY
#   HUBOT_TWITTER_<ACC>_CONSUMER_SECRET
#   HUBOT_TWITTER_<ACC>_ACCESS_TOKEN
#   HUBOT_TWITTER_<ACC>_ACCESS_TOKEN_SECRET
#
# Commands:
#   hubot tweet <text> - Post a tweet to twitter using the default account
#   hubot tweet@<account> <text> - Post a tweet to twitter using said account
#   hubot delete tweet with account <account> and id <id> - Delete that specific tweet
#   hubot list twitter accounts - Show available Twitter accounts
#
# Author:
#   Johannes Lauinger <jlauinger@d120.de>
#   Gordon Koo (https://github.com/gkoo)

Twit = require "twit"

config = []
twits = []
accounts = process.env.HUBOT_TWITTER_ACCOUNTS.split ','

for account in accounts
  account = account.toUpperCase()
  config[account] =
    consumer_key: process.env["HUBOT_TWITTER_#{account}_CONSUMER_KEY"]
    consumer_secret: process.env["HUBOT_TWITTER_#{account}_CONSUMER_SECRET"]
    access_token: process.env["HUBOT_TWITTER_#{account}_ACCESS_TOKEN"]
    access_token_secret: process.env["HUBOT_TWITTER_#{account}_ACCESS_TOKEN_SECRET"]

getTwitFor = (account) ->
  account = account.toUpperCase()
  unless twits[account]
    twits[account] = new Twit config[account]
  return twits[account]

accountExists = (account) ->
  return config[account.toUpperCase()]?

doTweet = (msg, account, tweet, robot) ->
  return if !tweet || !account
  twit = getTwitFor account
  twit.post 'statuses/update', { status: tweet }, (err, reply) ->
    if err
      msg.send "Error sending tweet!"
    else
      username = reply?.user?.screen_name
      id = reply.id_str
      if (username && id)
        msg.send "It's done! Tweet URL: https://www.twitter.com/#{username}/status/#{id}"

removeTweet = (msg, account, id, robot) ->
  return if !id || !account
  twit = getTwitFor account
  twit.post "statuses/destroy/#{id}", {}, (err, reply) ->
    if err
      msg.send "Error deleting tweet!"
    else
      msg.send "OK, tweet deleted."


module.exports = (robot) ->

  robot.respond /(show|list)( all)? twitter acc(ount)?s(, please!?)?/i, (msg) ->
    unless accounts
      msg.send "Please set the HUBOT_TWITTER_ACCOUNTS environment variable."
    readableAccounts = "@" + accounts.join(", @")
    msg.reply "I can tweet from these accounts: #{readableAccounts}"

  robot.respond /tweet \s*(.+)?/i, (msg) ->
    doTweet msg, accounts[0], msg.match[1], robot

  robot.respond /tweet@(\S+?) \s*(.+)?/i, (msg) ->
    unless accountExists msg.match[1]
      msg.reply "I can't tweet from that account: #{msg.match[1]}. Did you configure it?"
      return
    doTweet msg, msg.match[1], msg.match[2], robot

  robot.respond /delete tweet with account (\S+) and id (\S+)/i, (msg) ->
    unless accountExists msg.match[1]
      msg.reply "I don't know that account: #{msg.match[1]}. Did you configure it?"
      return
    removeTweet msg, msg.match[1], msg.match[2], robot
