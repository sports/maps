{spawn} = require 'child_process'
fs = require 'fs'
path = require 'path'
request = require 'request'
mkdir = require('mkdirp').sync
humanize = require 'humanize-plus'
_ = require 'underscore'
async = require 'async'
colors = require 'colors'

inputFile = path.join(process.cwd(), 'athletes', 'college-football-with-geocodes.json')
mapsDir = path.join(process.cwd(), 'maps')
athletes = JSON.parse(fs.readFileSync(inputFile, 'utf8'))

createPoint = ({displayName, height, latLng, weight, birthPlace}, additionalProperties={}) ->
  feet = Math.floor(height / 12)
  inches = height % 12
  formattedHeight = "#{feet}' #{inches}''"

  {city, state, country}  = birthPlace
  formattedBirthplace = []
  formattedBirthplace.push(humanize.titleCase(city.toLowerCase())) if city
  formattedBirthplace.push(state) if state
  formattedBirthplace.push(country) if country and country isnt 'USA'
  formattedBirthplace = formattedBirthplace.join(', ')

  feature =
    type: 'Feature'
    geometry:
      type: 'Point'
      coordinates: [
        latLng.lng
        latLng.lat
      ]
    properties:
      'Name': displayName
      'Height': formattedHeight
      'Weight': "#{weight} lbs"
      'Birthplace': formattedBirthplace
      'marker-symbol': 'america-football'

  _.extend(feature.properties, additionalProperties)
  feature

writeMap = (file, features) ->
  mkdir(path.dirname(file))
  collection = {features, type: 'FeatureCollection'}
  fs.writeFileSync(file, JSON.stringify(collection, null, 2))

generateAllAthletesMap = (athletes) ->
  features = []
  features.push(createPoint(athlete)) for athlete in athletes
  writeMap(path.join(mapsDir, 'college-football.geojson'), features)

generateHeightsMap = (athletes) ->
  athletes = athletes.filter ({height}) -> height > 0
  athletes = _.sortBy(athletes, 'height')
  shortest = athletes[0...1000]
  tallest = athletes[-1000..]
  features = []
  features.push(createPoint(athlete, 'marker-color': '#9F8170')) for athlete in shortest
  features.push(createPoint(athlete, 'marker-color': '#71BC78')) for athlete in tallest
  writeMap(path.join(mapsDir, 'college-football-heights.geojson'), features)

generateWeightsMap = (athletes) ->
  athletes = athletes.filter ({weight}) -> weight > 0
  athletes = _.sortBy(athletes, 'weight')
  lightest = athletes[0...1000]
  heaviest = athletes[-1000..]
  features = []
  features.push(createPoint(athlete, 'marker-color': '#75B2DD')) for athlete in lightest
  features.push(createPoint(athlete, 'marker-color': '#A45A52')) for athlete in heaviest
  writeMap(path.join(mapsDir, 'college-football-weights.geojson'), features)

generateBmiMap = (athletes) ->
  athletes = athletes.filter (athlete) ->
    {height, weight} = athlete
    if height > 0 and weight > 0
      athlete.bmi = Math.floor((weight / (height * height)) * 703)
      athlete.bmi > 30
    else
      false
  features = []
  for athlete in athletes
    features.push(createPoint(athlete, {'marker-color': '#F59D92', 'BMI': athlete.bmi}))
  writeMap(path.join(mapsDir, 'college-football-bmi.geojson'), features)

generateTopoJson = ->
  console.log 'Generating TopoJSON files'.green
  commands = []
  command = require.resolve('.bin/topojson')
  for map in fs.readdirSync(mapsDir)
    extension = path.extname(map)
    continue unless extension is '.geojson'
    do (map, extension) ->
      commands.push (callback) ->
        geoJsonFile = path.join(mapsDir, map)
        topoJsonFile = path.join(mapsDir, "#{path.basename(map, extension)}.topojson")
        console.log "Converting #{path.basename(geoJsonFile).cyan} to #{path.basename(topoJsonFile).cyan}"
        process = spawn(command, ['-p', '-o', topoJsonFile, geoJsonFile], {stdio: 'inherit'})
        process.on 'exit', -> callback()
  async.waterfall(commands)

generateAllAthletesMap(athletes)
generateHeightsMap(athletes)
generateWeightsMap(athletes)
generateBmiMap(athletes)
generateTopoJson()
