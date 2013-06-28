fs = require 'fs'
path = require 'path'
request = require 'request'
mkdir = require('mkdirp').sync

if apiKey = process.env.MAPQUEST_API_KEY
  outputFile = path.join(process.cwd(), 'athletes', 'college-football-with-geocodes.json')
  athletes = JSON.parse(fs.readFileSync(path.join(process.cwd(), 'athletes', 'college-football.json'), 'utf8'))
  atheletes = athletes.filter (athlete) ->
    {city, state, country} = athlete.birthPlace ? {}
    city or state or country

  geocodedAthletes = []

  requestAthletes = ->
    if athletes.length is 0
      console.log()
      mkdir(path.dirname(outputFile))
      fs.writeFileSync(outputFile, JSON.stringify(geocodedAthletes, null, 2))
      return

    athleteChunk = athletes.splice(0, 100)
    locations = []
    for athlete in athleteChunk
      {city, state, country} = athlete.birthPlace
      address = []
      address.push(city) if city
      address.push(state) if state
      address.push(country) if country
      locations.push(address.join(', '))

    options =
      url: "http://www.mapquestapi.com/geocoding/v1/batch?key=#{apiKey}"
      json: true
      qs:
        json: JSON.stringify({locations})
        outFormat: 'geojson'

    request options, (error, response, body) ->
      if error?
        console.error(error)
      else
        for result, index in body.results
          latLng = result.locations[0]?.latLng
          if latLng?
            athlete = athleteChunk[index]
            athlete.latLng = latLng
            geocodedAthletes.push(athlete)
        process.stdout.write("\rGeocoded athletes: #{geocodedAthletes.length}")
        setTimeout(requestAthletes, 100)

  requestAthletes()
else
  console.log 'Missing required MAPQUEST_API_KEY environment variable'
