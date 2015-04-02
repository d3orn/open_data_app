d3.json('ch.json', function(err, geojson_switzerland) {
  if (err) {
    return console.error(err);
  }
  console.log('Step 1 - loading GeoJSON data', geojson_switzerland);
  d3.csv('data.csv', (function(d) {
    var k;
    for (k in d) {
      if (k !== 'canton') {
        d[k] = +d[k];
      }
    }
    return d;
  }), function(err, data) {
    var cantons, height, path, svg, switzerland, width, zoom;
    if (err) {
      return console.error(err);
    }
    console.log('Step 2 - load my data', data);
    switzerland = topojson.feature(geojson_switzerland, geojson_switzerland.objects.cantons);
    console.log(switzerland);
    data.forEach(function(row) {
      switzerland.features.some(function(canton) {
        var k;
        if (canton.properties.abbr === row.canton) {
          for (k in row) {
            canton.properties[k] = row[k];
          }
          return true;
        }
      });
    });
    console.log('Step 3 - Check resulting dataset', switzerland);
    svg = d3.select('svg');
    width = parseInt(d3.select('svg').style('width'));
    height = parseInt(d3.select('svg').style('height'));
    path = d3.geo.path().projection(null);
    cantons = svg.select('#main').selectAll('path.canton').data(switzerland.features).enter().append('path').attr('class', 'canton').attr('d', path).style('stroke', 'grey').attr('stroke-width', 1);
    svg.select('#main').selectAll('text').data(switzerland.features).enter().append('g').attr('transform', function(d) {
      return 'translate(' + path.centroid(d) + ')';
    }).append('text').text(function(d) {
      return d.properties.abbr;
    });
    d3.select('#selector').selectAll('button').data(d3.keys(data[0])).enter().append('button').text(String).on('click', function(key) {
      var hue, scale;
      scale = d3.scale.linear().domain(d3.extent(data, function(d) {
        return d[key];
      })).range([1, 0.5]);
      console.log(scale.domain());
      hue = Math.random() * 360;
      d3.selectAll('path.canton').transition().attr('fill', function(d) {
        return d3.hsl(hue, 1, scale(d.properties[key]));
      });
      d3.selectAll('text').attr('transform', function(d) {
        return 'translate(30,-30)scale(2)rotate(30)';
      }).transition().ease('bounce').delay(function(d, i) {
        return i * 50;
      }).attr('transform', function(d) {
        return 'translate(0,0)scale(' + 1.5 - scale(d.properties[key]) + ')rotate(0)';
      });
    });
    console.log('step 7');
    zoom = d3.behavior.zoom().scaleExtent([1, 10]).on('zoom', function() {
      d3.select('#main').attr({
        transform: 'translate(' + d3.event.translate[0] + ',' + d3.event.translate[1] + ') scale(' + d3.event.scale + ')'
      });
    });
    svg.call(zoom);
  });
});


