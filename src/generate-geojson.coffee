fs = require 'fs'
path = require 'path'
request = require 'request'
mkdir = require('mkdirp').sync

inputFile = path.join(process.cwd(), 'athletes', 'college-football-with-geocodes.json')
athletes = JSON.parse(fs.readFileSync(inputFile, 'utf8'))

features = []
for {latLng, displayName} in athletes
  features.push
    type: 'Feature'
    geometry:
      type: 'Point'
      coordinates: [
        latLng.lng
        latLng.lat
      ]
    properties:
      name: displayName

outputFile = path.join(process.cwd(), 'maps', 'college-football.geojson')
mkdir(path.dirname(outputFile))
fs.writeFileSync(outputFile, JSON.stringify({type: 'FeaturedCollection', features}, null, 2))
