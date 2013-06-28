fs = require 'fs'
path = require 'path'
request = require 'request'
mkdir = require('mkdirp').sync

if apiKey = process.env.ESPN_API_KEY
  outputFile = path.join(process.cwd(), 'athletes', 'college-football.json')
  baseUrl = "http://api.espn.com/v1/sports/football/college-football/athletes?apikey=#{apiKey}"
  athletes = []

  requestAthletes = (offset=0) ->
    options =
      url: "#{baseUrl}&offset=#{offset}"
      json: true

    request options, (error, response, body) ->
      if error?
        console.error(error)
      else
        for athlete in body.sports[0].leagues[0].athletes
          delete athlete.links
          athletes.push(athlete)
        offset = body.resultsOffset + body.resultsLimit
        if offset < body.resultsCount
          setTimeout((-> requestAthletes(offset)), 350)
        else
          mkdir(path.dirname(outputFile))
          fs.writeFileSync(outputFile, JSON.stringify(athletes, null, 2))

  requestAthletes()
else
  console.log 'Missing required ESPN_API_KEY environment variable'
