# Load world data
d3.json 'ch.json', (err, geojson_switzerland) ->
  if err
    return console.error(err)
  console.log 'Step 1 - loading GeoJSON data', geojson_switzerland
  # Load my data
  d3.csv 'data.csv', ((d) ->
    for k of d
      if k != 'canton'
        d[k] = +d[k]
    d
  ), (err, data) ->
    if err
      return console.error(err)
    console.log 'Step 2 - load my data', data
    # extract only cantons from the GeoJSON data
    switzerland = topojson.feature(geojson_switzerland, geojson_switzerland.objects.cantons)
    console.log switzerland
    # Combine data sets
    data.forEach (row) ->
      # for each row in data, look for the canton abbreviation in geodata
      switzerland.features.some (canton) ->
        if canton.properties.abbr == row.canton
          # if found, add all data to the countries properties
          for k of row
            canton.properties[k] = row[k]
          return true
        return
      return
    console.log 'Step 3 - Check resulting dataset', switzerland
    # store the SVG element
    svg = d3.select('svg')
    # Compute width and height of the SVG element (in pixels)
    width = parseInt(d3.select('svg').style('width'))
    height = parseInt(d3.select('svg').style('height'))
    # define how paths are generated
    path = d3.geo.path().projection(null)
    # draw the cantons
    cantons = svg.select('#main').selectAll('path.canton').data(switzerland.features).enter().append('path').attr('class', 'canton').attr('d', path).style('stroke', 'grey').attr('stroke-width', 1)
    svg.select('#main').selectAll('text').data(switzerland.features).enter().append('g').attr('transform', (d) ->
      'translate(' + path.centroid(d) + ')'
    ).append('text').text (d) ->
      d.properties.abbr
    d3.select('#selector').selectAll('button').data(d3.keys(data[0])).enter().append('button').text(String).on 'click', (key) ->
      scale = d3.scale.linear().domain(d3.extent(data, (d) ->
        d[key]
      )).range([
        1
        0.5
      ])
      console.log scale.domain()
      hue = Math.random() * 360
      d3.selectAll('path.canton').transition().attr 'fill', (d) ->
        d3.hsl hue, 1, scale(d.properties[key])
      d3.selectAll('text').attr('transform', (d) ->
        'translate(30,-30)scale(2)rotate(30)'
      ).transition().ease('bounce').delay((d, i) ->
        i * 50
      ).attr 'transform', (d) ->
        'translate(0,0)scale(' + 1.5 - scale(d.properties[key]) + ')rotate(0)'
      return
    # Step 7 - Allow dragging and zooming
    console.log 'step 7'
    zoom = d3.behavior.zoom().scaleExtent([
      1
      10
    ]).on('zoom', ->
      d3.select('#main').attr transform: 'translate(' + d3.event.translate[0] + ',' + d3.event.translate[1] + ') scale(' + d3.event.scale + ')'
      return
    )
    # the zoom effect should be possible on the whole SVG element
    svg.call zoom
    return
  return
