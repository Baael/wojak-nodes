// Generated by CoffeeScript 1.9.2
(function() {
  module.exports = function(RED) {
    var BoxcarCredentialsNode, BoxcarNotificationNode, http, mustache, options;
    http = require('https');
    mustache = require("mustache");
    options = {
      host: "new.boxcar.io",
      path: "/api/notifications",
      port: 443,
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded'
      }
    };
    BoxcarCredentialsNode = function(config) {
      var node;
      RED.nodes.createNode(this, config);
      node = this;
      return this.api_key = config.api_key;
    };
    BoxcarNotificationNode = function(config) {
      var key, node, value;
      RED.nodes.createNode(this, config);
      node = this;
      for (key in config) {
        value = config[key];
        node[key] = value;
      }
      this.broker = config.broker;
      this.credentials = RED.nodes.getNode(this.broker);
      this.api_key = this.credentials.api_key;
      return this.on('input', (function(_this) {
        return function(msg) {
          var body, req, request;
          node.status({
            fill: "grey",
            shape: "dot",
            text: "processing"
          });
          request = {
            title: node.title || msg.topic,
            sound: msg.sound || node.sound,
            source_name: msg.source_name || node.source_name,
            icon_url: node.icon_url,
            long_message: mustache.render(node.message, msg)
          };
          body = "user_credentials=" + node.api_key;
          for (key in request) {
            value = request[key];
            body += "&notification[" + key + "]=" + (encodeURIComponent(value));
          }
          options.headers['Content-Length'] = body.length;
          req = http.request(options, function(res) {
            if (res.statusCode === 201) {
              return node.status({});
            }
          });
          req.on('error', function(e) {
            return node.status({
              shape: "dot",
              fill: "red",
              text: "error!"
            });
          });
          req.write(body);
          req.end();
          return node.send(msg);
        };
      })(this));
    };
    RED.nodes.registerType("boxcar-credentials", BoxcarCredentialsNode);
    return RED.nodes.registerType("boxcar-notification", BoxcarNotificationNode);
  };

}).call(this);
