show = (elem) ->
  region = elem.getAttribute('data-region')
  svg = d3.select('svg')
  d3.selectAll('g').style("display", "none")
  svg.select('#' + region).style("display", "block")

resize = ->
  console.log 'resize '
  # adjust things when the window size changes
  svg = d3.select('svg')
  width = parseInt(svg.style('width'))

  # scale each individual object according to theire own width/height and
  # window width/height
  # d3.selectAll("g").attr("transform", "scale(" + width / 600 + "), translate(" + width / 2 + ", 0)");
  # probably all regions need ratio and translate

  # translate(-centerX*(factor-1), -centerY*(factor-1))
  # scale(factor)
  ratio = 1
  ratio = 1.25 if window.innerWidth <= 750
  test = width * -1
  # d3.selectAll("g").attr("transform", "scale(" + ratio + ")");
  svg.select('#zentralschweiz').attr("transform", "scale(" + ratio + "), translate(" + @regions['Zentralschweiz'].origin + ")");
  svg.select('#mittelland').attr("transform", "scale(" + ratio + "), translate(" + @regions['Mittelland'].origin + ")");
  svg.select('#ostschweiz').attr("transform", "scale(" + ratio + "), translate(" + @regions['Ostschweiz'].origin + ")");
  svg.select('#westschweiz').attr("transform", "scale(" + ratio + "), translate(" + @regions['Westschweiz'].origin + ")");


  # map.style('width', width + 'px').style 'height', height + 'px'
  # # resize the map
  # map.select('.land').attr 'd', path
  # map.selectAll('.state').attr 'd', path
  return

d3.select(window).on 'resize', resize

# Scale
windowWidth = window.innerWidth

if windowWidth <= 750
  console.log 'Mobile'
  # d3.select('g').attr transform: 'translate(-120,0)'
  # d3.selectAll

@regions = []
@regions[0] = '1'

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
  ), (err, @data) =>
    if err
      return console.error(err)
    console.log 'Step 2 - load my data', data
    # extract only cantons from the GeoJSON data
    switzerland = topojson.feature(geojson_switzerland, geojson_switzerland.objects.cantons)
    console.log switzerland



    d3.json 'regions.json', (err, regions) ->
      if err
        return console.error(err)
      @region_names = []
      @all_regions = regions.regions


      for key, region of @all_regions
        @region_names.push(region.name)
        @regions[region.name] = {features: [], color: region.color, origin: region.origin}

        # d3.select('#selector').selectAll('button').data(@region_names).enter().append('button').attr('class', 'button').text(String)

      # split up cantons into the different regions

      # Combine data sets
      @data.forEach (row) =>
        # for each row in data, look for the canton abbreviation in geodata
        switzerland.features.some (canton) =>
          if canton.properties.abbr == row.canton
            # if found, add all data to the countries properties
            for k of row
              canton.properties[k] = row[k]
            # add region prop
            for region in @all_regions
              for rcanton in region.cantons
                if rcanton.name is row.canton
                  canton.properties['region'] = region.name
                  @regions[region.name].features.push canton


      console.log @regions

      console.log 'Step 3 - Check resulting dataset', switzerland
      # store the SVG element
      svg = d3.select('svg')
      # Compute width and height of the SVG element (in pixels)
      width = parseInt(d3.select('svg').style('width'))
      height = parseInt(d3.select('svg').style('height'))
      # define how paths are generated
      path = d3.geo.path().projection(null)
      # draw the cantons
      console.log 'features'
      console.log switzerland.features

      # for info in data
      #
      console.log @regions

# zentral: -370, -50
# Ostschwiz: translate(-497,-2)
# Westschweiz translate(-120,-72)
# Mittelland translate(-265,-45)


      westschweiz = svg.select('#westschweiz').selectAll('path.canton').data(@regions['Westschweiz'].features)
      .enter()
      .append('path')
      .attr('class', 'canton')
      .attr('d', path)
      .style('fill', @regions['Westschweiz'].color)
      .style('stroke', 'white')
      .attr('stroke-width', 1)

      ostschweiz = svg.select('#ostschweiz').selectAll('path.canton').data(@regions['Ostschweiz'].features)
      .enter()
      .append('path')
      .attr('class', 'canton')
      .attr('d', path)
      .style('fill', @regions['Ostschweiz'].color)
      .style('stroke', 'white')
      .attr('stroke-width', 1)

      zentralschweiz = svg.select('#zentralschweiz').selectAll('path.canton').data(@regions['Zentralschweiz'].features)
      .enter()
      .append('path')
      .attr('class', 'canton')
      .attr('d', path)
      .style('fill', @regions['Zentralschweiz'].color)
      .style('stroke', 'white')
      .attr('stroke-width', 1)

      mittelland = svg.select('#mittelland').selectAll('path.canton').data(@regions['Mittelland'].features)
      .enter()
      .append('path')
      .attr('class', 'canton')
      .attr('d', path)
      .style('fill', @regions['Mittelland'].color)
      .style('stroke', 'white')
      .attr('stroke-width', 1)

      d3.selectAll('g').style("display", "none")

      resize()

      # for region in regions
#   for canton in regions.cantons
#     draw canton and add data

    # d3.select('#selector').selectAll('button').data(d3.keys(data[0])).enter().append('button').text(String).on 'click', (key) ->
    #   scale = d3.scale.linear().domain(d3.extent(data, (d) ->
    #     d[key]
    #   )).range([
    #     1
    #     0.5
    #   ])
    #   console.log scale.domain()
    #   hue = Math.random() * 360
    #   d3.selectAll('path.canton').transition().attr 'fill', (d) ->
    #     d3.hsl hue, 1, scale(d.properties[key])
    #   d3.selectAll('text').attr('transform', (d) ->
    #     'translate(30,-30)scale(2)rotate(30)'
    #   ).transition().ease('bounce').delay((d, i) ->
    #     i * 50
    #   ).attr 'transform', (d) ->
    #     'translate(0,0)scale(' + 1.5 - scale(d.properties[key]) + ')rotate(0)'
    #   return

    return
  return


