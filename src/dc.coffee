# Hubot dependencies
{Robot, Adapter, TextMessage} = require 'hubot'

net = require 'net'

class DCBot extends Adapter
  constructor: (@robot) ->
    @nick = process.env.HUBOT_DC_NICK
    @server = process.env.HUBOT_DC_SERVER
    @robot.logger.info "hubot-dc: Adapter loaded."

  # Public: Raw method for sending data back to the chat source. Extend this.
  #
  # envelope - A Object with message, room and user details.
  # strings  - One or more Strings for each message to send.
  #
  # Returns nothing.
  send: (envelope, strings...) ->

  # Public: Raw method for building a reply and sending it back to the chat
  # source. Extend this.
  #
  # envelope - A Object with message, room and user details.
  # strings  - One or more Strings for each reply to send.
  #
  # Returns nothing.
  reply: (envelope, strings...) ->

  # Public: Raw method for invoking the bot to run. Extend this.
  #
  # Returns nothing.
  run: ->
    options = 
      port = 411
      host = @server

    bot = net.connect options

    bot.addEventListener 'data' (data) ->
      @robot.logger.info data

exports.use = (robot) ->
  new DCBot robot
