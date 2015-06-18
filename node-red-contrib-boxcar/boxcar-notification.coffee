module.exports = (RED)->
  http = require('https')
  mustache = require("mustache")

  options =
    host:   "new.boxcar.io"
    path:   "/api/notifications"
    port:   443
    method: 'POST'
    headers:
      'Content-Type': 'application/x-www-form-urlencoded',


  BoxcarCredentialsNode = (config)->
    RED.nodes.createNode this, config

    node = this
    this.api_key     = config.api_key


  BoxcarNotificationNode = (config)->
    RED.nodes.createNode this, config

    node = this
    node[key] = value for key,value of config

    this.broker   = config.broker
    this.credentials   = RED.nodes.getNode this.broker
    this.api_key  = this.credentials.api_key

    this.on 'input', (msg)=>

      node.status
        fill:  "grey"
        shape: "dot"
        text:  "processing"

      request =
        title:        node.title   || msg.topic
        sound:        msg.sound || node.sound
        source_name:  msg.source_name || node.source_name
        icon_url:     node.icon_url
        long_message: mustache.render node.message, msg

      body = "user_credentials=#{node.api_key}"

      for key, value of request
        body += "&notification[#{key}]=#{encodeURIComponent value}"

      options.headers['Content-Length'] = body.length

      req = http.request options, (res)->
        node.status {} if res.statusCode == 201

      req.on 'error', (e)->
        node.status
          shape: "dot"
          fill:  "red"
          text:  "error!"

      req.write body
      req.end()

      node.send msg

  RED.nodes.registerType "boxcar-credentials",  BoxcarCredentialsNode
  RED.nodes.registerType "boxcar-notification", BoxcarNotificationNode