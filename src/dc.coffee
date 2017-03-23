{Robot, Adapter, TextMessage, EnterMessage, LeaveMessage, Message} = require 'hubot'

net = require 'net'
Log = require 'log'

logger = new Log process.env.HUBOT_LOG_LEVEL or 'info'

class DCBot extends Adapter
  constructor: (@robot) ->
    super
    self = @
    self.nick = process.env.HUBOT_DC_NICK
    self.server = process.env.HUBOT_DC_SERVER
    self.description = process.env.HUBOT_DC_DESCRIPTION
    self.spoofShare = process.env.HUBOT_DC_SPOOF_SHARE or 0
    self.socket = null
    self.robot.name = self.nick
    logger.info "hubot-dc: Adapter loaded."

  _rawSend: (command, arg) ->
    self = @
    logger.debug "[Sending To Hub]: " + command + " " + arg
    if self.socket
      if not arg
        self.socket.write "$" + command + "|", "binary"
      else
        self.socket.write "$" + command + " " + arg + "|", "binary"

  send: (envelope, messages...) ->
    self = @
    for message in messages
      if message isnt ''
        self.socket.write "<" + self.nick + "> " + messages + "|", "binary"

  reply: (envelope, messages...) ->
     self = @
     self.send envelope, messages

  run: ->
    self = @
    options = 
      port: 411
      host: @server

    self.socket = net.connect options, () -> 
      self.socket.on 'data', (data) ->
        cmd_str = data.toString 'ascii'
        cmd_reg = /\$([a-z]+) *([^|]*)/gi
        isCommand = false
        while m = cmd_reg.exec cmd_str
          ifCommand = true
          command = m[1]
          arg = m[2]
          logger.debug "[Received From Hub]: " + command + " " + arg
          self.socket.emit command, arg
        if not isCommand
          msg_reg = /<(.+)> ([^|]*)/gi
          while m = msg_reg.exec cmd_str
            sender = m[1]
            message = m[2]
            users = self.robot.brain.usersForFuzzyName sender
            logger.debug "[Received From " + sender + "] " + message
            self.socket.emit "message", sender, message

    self.socket.on "Hello", (name) ->
      newUser =
        id: name
        name: name
      self.robot.brain.userForId name, newUser
      self.receive new EnterMessage name
      if name == self.nick
        self._rawSend "MyINFO", "$ALL " + self.nick + " " + self.description + " <BOT>$ $0A$$" + self.spoofShare + "$"
        logger.info "hubot-dc: Adapter connected."
        self._rawSend "GetNickList"
        self.emit "connected"

    self.socket.on "NickList", (nicks) ->
      for name in nicks.split "$$"
        newUser =
          id: name
          name: name
        self.robot.brain.userForId name, newUser
        self.receive new EnterMessage name

    self.socket.on "HubName", (hubname) ->
      self._rawSend "ValidateNick", self.nick

    self.socket.on "Quit", (name) ->
      delete self.robot.brain.data.users[name]
      self.receive new LeaveMessage name

    self.socket.on "ValidateDenide", () ->
      self.nick = self.nick + "_"
      self.robot.name = self.nick
      self._rawSend "ValidateNick", self.nick

    self.socket.on "message", (sender, message) ->
      newUser = 
        id: sender
        name: sender
      if sender != self.nick
        self.receive new TextMessage newUser, message

exports.use = (robot) ->
  new DCBot robot
