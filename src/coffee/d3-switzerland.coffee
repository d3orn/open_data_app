@years = [2010, 2011, 2012, 2013, 2014]
@year = 2014
@field = 'Informatik'
@type = 'EFZ'
@gender = 'both'
@value = 'total'

@regions = []

@cantonsObjects = {'ZH' : {},'BE' : {},'LU' : {},'UR' : {},'SZ' : {},'OW' : {},'NW' : {},'GL' : {},
'ZG' : {},'FR' : {},'SO' : {},'BS' : {},'BL' : {},'SH' : {},'AR' : {},'AI' : {},'SG' : {},'GR' : {},'AG' : {},
'TG' : {},'TI' : {},'VD' : {},'VS' : {},'NE' : {},'GE' : {},'JU' : {}}

@svg = d3.select('svg')

tip = d3.select("body").append("div")
    .attr("class", "tip")
    .style("opacity", 0);

d3.select(window).on 'resize', resize

# Scale
windowWidth = window.innerWidth

# if windowWidth <= 750
$(document).ready =>
  dataCounter = 0
  for index, year of @years
    console.log year
    # loadData year. then ->
    #   dataCounter++
    #   if dataCounter is @years.length
    #     loadMap()
  loadData(2014).then ->
    loadSwitzerland().then ->
      loadRegions().then ->
        draw()

loadData = (year) ->
  deffered = jQuery.Deferred()
  d3.csv "#{year}.csv", (d) ->

    field = d.Ausbildungsfeld
    type = d.Ausbildungstyp

    obj = @cantonsObjects[d.Canton];
    if obj
      if not obj[year]
        obj[year] = {}
      if not obj[year][field]
        obj[year][field] = {}
      if not obj[year][field][type]
        obj[year][field][type] = {both: {}, men: {}, women: {}}
      obj[year][field][type].both = {total: d.Geschlecht_Total, dual: d.Geschlecht_Dual , full: d.Geschlecht_Vollschulisch }
      obj[year][field][type].women = {total: d.Frau_Total, dual: d.Frau_Dual , full: d.Frau_Vollschulisch }
      obj[year][field][type].men = {total: d.Mann_Total, dual: d.Mann_Dual , full: d.Mann_Vollschulisch }
  , -> deffered.resolve()
  deffered.promise()

loadSwitzerland = () ->
  deffered = jQuery.Deferred()
  d3.json 'ch.json', (err, geojson_switzerland) =>
    if err
      return console.error(err)

    @switzerland = topojson.feature(geojson_switzerland, geojson_switzerland.objects.cantons)
    deffered.resolve()
  deffered.promise()

loadRegions = () ->
  deffered = jQuery.Deferred()
  d3.json 'regions.json', (err, regions) ->
    if err
      return console.error(err)
    region_names = []
    @all_regions = regions.regions


    for key, region of @all_regions
      region_names.push(region.name)
      @regions[region.name] = {features: [], color: region.color, origin: region.origin}
    deffered.resolve()
  deffered.promise()

draw = ->
  combineData()

  @path = d3.geo.path().projection(null)

  for name of @regions
    drawRegion(name)

  update()
  resize()

  d3.selectAll('g').style("display", "none")
  @svg.select('#Westschweiz').style("display", "block")

  addEventListner()

addEventListner = ->
  @svg.selectAll 'path.canton'
  .on 'mousedown', tooltipShow
  .on 'mouseover', tooltipShow
  .on 'click', tooltipShow
  .on 'mouseup', tooltipHide
  .on 'mouseout', tooltipHide

combineData = ->
  for key, item of @cantonsObjects
    for year, data of item
      @switzerland.features.some (canton) =>
        if canton.properties.abbr is key
          canton.properties[year] = data

          for region in @all_regions
            for rcanton in region.cantons
              if rcanton.name is key
                canton.properties['region'] = region.name
                @regions[region.name].features.push canton





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

    # return
  # return

drawRegion = (regionName) =>
  features = @regions[regionName].features
  @svg.select("##{regionName}").selectAll('path.canton').data(features)
  .enter()
  .append('path')
  .attr('class', 'canton')
  .attr('d', @path)
  .style('fill', @regions[regionName].color)
  .style('stroke', 'white')
  .attr('stroke-width', 1)

  @svg.select("##{regionName}").selectAll('text').data(features)
  .enter()
  .append 'g'
  .attr 'class', 'text'
  .attr 'transform', (d) ->
    center = path.centroid(d)
    center[0] = center[0] - 5
    'translate('+center+')'
  .append('text')
  .text (d) ->
    d.properties.abbr

update = ->
  for name, region of @regions
    features = region.features
    max = 0
    min = 0
    for feature in features
      value = parseInt feature.properties[@year][@field][@type][@gender][@value]
      if value >= max
        max = value
      if value <= min
        min = value

    color = d3.rgb region.color

    scale = d3.scale.linear()
            .domain([min, max])
            .range([color.brighter(2), color.brighter(1), color, color.darker(1), color.darker(2)]);

    @svg.select("##{name}").selectAll('path.canton').data(features)
    .style 'fill', (d) =>
      value = parseInt d.properties[@year][@field][@type][@gender][@value]
      d3.rgb(scale(value))

show = (elem) ->
  region = elem.getAttribute('data-region')
  d3.selectAll('g').style("display", "none")
  @svg.select('#' + region).style("display", "block")

resize = ->
  # adjust things when the window size chan
  width = parseInt(svg.style('width'))

  console.log width

  # scale each individual object according to theire own width/height and
  # window width/height
  # d3.selectAll("g").attr("transform", "scale(" + width / 600 + "), translate(" + width / 2 + ", 0)");
  # probably all regions need ratio and translate

  # translate(-centerX*(factor-1), -centerY*(factor-1))
  # scale(factor)
  # ratio = 1.25
  # ratio = 1.25 if window.innerWidth <= 750

  @svg.select('#Zentralschweiz').attr("transform", "scale(" + width/212 + "), translate(" + @regions['Zentralschweiz'].origin + ")");
  @svg.select('#Mittelland').attr("transform", "scale(" + width/300 + "), translate(" + @regions['Mittelland'].origin + ")");
  @svg.select('#Ostschweiz').attr("transform", "scale(" + width/340 + "), translate(" + @regions['Ostschweiz'].origin + ")");
  @svg.select('#Westschweiz').attr("transform", "scale(" + width/400 + "), translate(" + @regions['Westschweiz'].origin + ")");


  # map.style('width', width + 'px').style 'height', height + 'px'
  # # resize the map
  # map.select('.land').attr 'd', path
  # map.selectAll('.state').attr 'd', path
  return

tooltipShow = (d, i) =>
  data = d.properties
  value = data[@year][@field][@type][@gender][@value]
  name = data.name
  .replace('Ã¨', 'è')
  .replace('Ã¢', 'â')
  .replace('Ã¼', 'ü')
  tip.transition()
  .duration 200
  .style 'opacity', .9
  tip.html "<h5>#{name}</h5>
           <p>#{value}</p>"
  .style("left", (d3.event.pageX) + "px")
  .style("top", (d3.event.pageY - 28) + "px");

tooltipHide = ->
  tip.transition()
  .duration 500
  .style 'opacity', 0
