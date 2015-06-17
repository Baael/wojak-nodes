module.exports = (RED)->
  Ivona = require 'ivona-node'
  slug  = require 'slug'
  fs    = require "fs"
  exec  = require('child_process').exec
  mustache = require "mustache"

  voices =
    '0': { gender: 'Female', lang: 'en-US', name: 'Salli' },
    '1': { gender: 'Male', lang: 'en-US', name: 'Joey' },
    '2': { gender: 'Female', lang: 'da-DK', name: 'Naja' },
    '3': { gender: 'Male', lang: 'da-DK', name: 'Mads' },
    '4': { gender: 'Female', lang: 'de-DE', name: 'Marlene' },
    '5': { gender: 'Male', lang: 'de-DE', name: 'Hans' },
    '6': { gender: 'Female', lang: 'en-AU', name: 'Nicole' },
    '7': { gender: 'Male', lang: 'en-AU', name: 'Russell' },
    '8': { gender: 'Female', lang: 'en-GB', name: 'Amy' },
    '9': { gender: 'Male', lang: 'en-GB', name: 'Brian' },
    '10': { gender: 'Female', lang: 'en-GB', name: 'Emma' },
    '11': { gender: 'Female', lang: 'en-GB-WLS', name: 'Gwyneth' },
    '12': { gender: 'Male', lang: 'en-GB-WLS', name: 'Geraint' },
    '13': { gender: 'Female', lang: 'cy-GB', name: 'Gwyneth' },
    '14': { gender: 'Male', lang: 'cy-GB', name: 'Geraint' },
    '15': { gender: 'Female', lang: 'en-IN', name: 'Raveena' },
    '16': { gender: 'Male', lang: 'en-US', name: 'Chipmunk' },
    '17': { gender: 'Male', lang: 'en-US', name: 'Eric' },
    '18': { gender: 'Female', lang: 'en-US', name: 'Ivy' },
    '19': { gender: 'Female', lang: 'en-US', name: 'Jennifer' },
    '20': { gender: 'Male', lang: 'en-US', name: 'Justin' },
    '21': { gender: 'Female', lang: 'en-US', name: 'Kendra' },
    '22': { gender: 'Female', lang: 'en-US', name: 'Kimberly' },
    '23': { gender: 'Female', lang: 'es-ES', name: 'Conchita' },
    '24': { gender: 'Male', lang: 'es-ES', name: 'Enrique' },
    '25': { gender: 'Female', lang: 'es-US', name: 'Penelope' },
    '26': { gender: 'Male', lang: 'es-US', name: 'Miguel' },
    '27': { gender: 'Female', lang: 'fr-CA', name: 'Chantal' },
    '28': { gender: 'Female', lang: 'fr-FR', name: 'Celine' },
    '29': { gender: 'Male', lang: 'fr-FR', name: 'Mathieu' },
    '30': { gender: 'Female', lang: 'is-IS', name: 'Dora' },
    '31': { gender: 'Male', lang: 'is-IS', name: 'Karl' },
    '32': { gender: 'Female', lang: 'it-IT', name: 'Carla' },
    '33': { gender: 'Male', lang: 'it-IT', name: 'Giorgio' },
    '34': { gender: 'Female', lang: 'nb-NO', name: 'Liv' },
    '35': { gender: 'Female', lang: 'nl-NL', name: 'Lotte' },
    '36': { gender: 'Male', lang: 'nl-NL', name: 'Ruben' },
    '37': { gender: 'Female', lang: 'pl-PL', name: 'Agnieszka' },
    '38': { gender: 'Male', lang: 'pl-PL', name: 'Jacek' },
    '39': { gender: 'Female', lang: 'pl-PL', name: 'Ewa' },
    '40': { gender: 'Male', lang: 'pl-PL', name: 'Jan' },
    '41': { gender: 'Female', lang: 'pl-PL', name: 'Maja' },
    '42': { gender: 'Female', lang: 'pt-BR', name: 'Vitoria' },
    '43': { gender: 'Male', lang: 'pt-BR', name: 'Ricardo' },
    '44': { gender: 'Male', lang: 'pt-PT', name: 'Cristiano' },
    '45': { gender: 'Female', lang: 'pt-PT', name: 'Ines' },
    '46': { gender: 'Female', lang: 'ro-RO', name: 'Carmen' },
    '47': { gender: 'Male', lang: 'ru-RU', name: 'Maxim' },
    '48': { gender: 'Female', lang: 'ru-RU', name: 'Tatyana' },
    '49': { gender: 'Female', lang: 'sv-SE', name: 'Astrid' },
    '50': { gender: 'Female', lang: 'tr-TR', name: 'Filiz' }


  IvonaCredentialsNode = (config)->
    RED.nodes.createNode this, config

    node = this
    this.api_key     = config.api_key
    this.credentials = config.credentials
    this.password    = config.password




  IvonaSayNode = (config)->
    RED.nodes.createNode this, config

    node = this
    this.voice        = config.voice
    this.broker       = config.broker
    this.credentials  = RED.nodes.getNode this.broker
    this.message      = config.message
    this.exec         = config.exec
    this.params       = config.params
    this.dir          = config.dir

    this.queue = []
    this.playing = false

    play = (param)->
      unless param?
        node.setStatus null
        return
      node.queue.push param if node.playing
      node.setStatus "playing #{node.queue.length + 1}", "green"
      return if node.playing
      node.playing = true
      exec param, =>
        node.playing = false
        play node.queue.shift()


    node.setStatus = (text, color = "green")->
      return node.status {} unless text?
      node.status
        fill:  color
        shape: "dot"
        text:  text

    node.context = RED.settings.functionGlobalContext

    this.on 'input', (msg, context)=>

      node.context.ivona_pool ||= {}

      node.context.ivona_pool[node.credentials.name] ||= new Ivona
        accessKey: node.credentials.api_key
        secretKey: node.credentials.password

      ivona = node.context.ivona_pool[node.credentials.name]

      text     =  mustache.render node.message, msg

      msg.slug = slug "#{text}"
      msg.voice_id = slug "#{text}"

      for key, value of voices[node.voice]
        msg["voice_#{key}"] = slug value, '-'


      msg.file  = mustache.render(node.dir, msg).toLowerCase()
      _exec = mustache.render node.exec, msg

      fs.exists msg.file, (exists)->
        if exists
          node.send msg
          play _exec if node.exec.length > 0
        else
          node.setStatus "requesting", "yellow"
          ivona
            .createVoice text, {body: {voice: voices[node.voice]  } }
            .on 'end', ->
              node.send msg
              play _exec if node.exec.length > 0
            .pipe fs.createWriteStream msg.file

      return null


  RED.nodes.registerType "ivona-credentials", IvonaCredentialsNode

  RED.nodes.registerType "ivona-say", IvonaSayNode
