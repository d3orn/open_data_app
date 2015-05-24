@years = [2010, 2011, 2012, 2013, 2014]
@year = 2014
@field = 'Informatik'
@type = 'EFZ'
@gender = 'both'
@value = 'total'

@regions = []
@active = 'Westschweiz'

@cantonsObjects = {'ZH' : {},'BE' : {},'LU' : {},'UR' : {},'SZ' : {},'OW' : {},'NW' : {},'GL' : {},
'ZG' : {},'FR' : {},'SO' : {},'BS' : {},'BL' : {},'SH' : {},'AR' : {},'AI' : {},'SG' : {},'GR' : {},'AG' : {},
'TG' : {},'TI' : {},'VD' : {},'VS' : {},'NE' : {},'GE' : {},'JU' : {}}

@svg = d3.select('svg')

tip = d3.select("body").append("div")
    .attr("class", "tip")
    .style("opacity", 0);

# Scale
windowWidth = window.innerWidth

$('.right-small').click ->
  $('.off-canvas-wrap').foundation('offcanvas', 'show', 'move-left')

# if windowWidth <= 750
$(document).ready =>

  dataCounter = 0
  for index, year of @years
    $('#year').append($('<option/>', {
        value: year,
        text : year
    }))
  loadJSON().then =>
    loadSwitzerland().then ->
      loadRegions().then ->
        draw()
    # loadData(year).then =>
    #   dataCounter++
    #   if dataCounter is @years.length
    #     loadSwitzerland().then ->
    #       loadRegions().then ->
    #         draw()

loadJSON = ->
  deffered = jQuery.Deferred()

  d3.json "10-14.json.gz", (d) ->
    console.log d
    @cantonsObjects = d
    deffered.resolve()
  deffered.promise()

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
      @regions[region.name] = {features: [], color: region.color, origin: region.origin, width: region.origWidth, height: region.origHeight}
    deffered.resolve()
  deffered.promise()

draw = ->
  combineData()

  @path = d3.geo.path().projection(null)

  for name of @regions
    drawRegion(name)

  updateFields()
  update()
  resize()

  d3.selectAll('g').style("display", "none")
  @svg.select('#Westschweiz').style("display", "block")

  addEventListner()

addEventListner = ->
  d3.select(window).on 'resize', resize

  @svg.selectAll 'path.canton'
  .on 'mousedown', tooltipShow
  .on 'mouseover', tooltipShow
  .on 'click', tooltipShow
  .on 'mouseup', tooltipHide
  .on 'mouseout', tooltipHide

  @svg.selectAll 'text'
  .on 'mousedown', tooltipShow
  .on 'mouseover', tooltipShow
  .on 'click', tooltipShow
  .on 'mouseup', tooltipHide
  .on 'mouseout', tooltipHide

  that = this
  $('#year').change ->
    that.year = $(this).val()
    updateFields()
    update()

  $('#field').change ->
    that.field = $(this).val()
    update()

  $('#type').change ->
    that.type = $(this).val()
    update()

  $('#gender').change ->
    that.gender = $(this).val()
    update()

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
  .style('fill', '#FFF')
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

    scale = d3.scale.quantize()
            .domain([min, max])
            .range([color.brighter(3), color.brighter(1), color, color.darker(1), color.darker(3)]);

    if min is max
      scale = (int) -> color.brighter(3)

    if name is @active
      $('#scale').children().each (index, item) ->
        step = max/5*index
        nextStep = max/5*(index+1)
        if step is nextStep
          $(item).find('.box').css("background-color", scale(step))
          $(item).find('.content').html("<p>#{parseInt step}</p>")
          $('#scale li').not(item).hide()
          return false
        else
          $(item).show()
          $(item).find('.box').css("background-color", scale(step))
          $(item).find('.content').html("<p>#{parseInt step} - #{parseInt(nextStep)}</p>")

    @svg.select("##{name}").selectAll('path.canton').data(features)
    .style 'fill', (d) =>
      value = parseInt d.properties[@year][@field][@type][@gender][@value]
      d3.rgb(scale(value))

updateFields = ->
  fields = @cantonsObjects['BE'][year]
  for field of fields
    $('#field').append($('<option/>', {
      value: field,
      text : field
    }))

  $("[data-region=#{@active}]").addClass('active')
  $("#year").val(@year)
  $("#field").val(@field)
  $("#type").val(@type)
  $("#gender").val(@gender)

show = (elem) ->
  $(elem).addClass('active')
  $('.button').not(elem).removeClass('active')
  region = elem.getAttribute('data-region')
  @active = region
  d3.selectAll('g').style("display", "none")
  @svg.select('#' + region).style("display", "block")
  update()
  # $('.off-canvas-wrap').foundation('offcanvas', 'hide', 'move-left')

resize = ->
  width = parseInt(svg.style('width')) - 15
  height = parseInt(svg.style('height')) - 15

  # translate(-centerX*(factor-1), -centerY*(factor-1))
  # scale(factor)
  # ratio = 1.25
  # ratio = 1.25 if window.innerWidth <= 750
  for name, region of @regions
    widthRatio = width / parseInt(region.width)
    heightRatio = height / parseInt(region.height)
    ratio = Math.min(widthRatio, heightRatio)
    @svg.select("##{name}").attr("transform", "scale(" + ratio + "), translate(" + region.origin + ")");

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
           <p>#{@field} / #{@type}</p>
           <p>#{value}</p>"
  .style("left", (d3.event.pageX) + "px")
  .style("top", (d3.event.pageY - 28) + "px");

tooltipHide = ->
  tip.transition()
  .duration 500
  .style 'opacity', 0
