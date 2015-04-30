var resize, show, windowWidth;

show = function(elem) {
  var region, svg;
  region = elem.getAttribute('data-region');
  svg = d3.select('svg');
  d3.selectAll('g').style("display", "none");
  return svg.select('#' + region).style("display", "block");
};

resize = function() {
  var ratio, svg, test, width;
  console.log('resize ');
  svg = d3.select('svg');
  width = parseInt(svg.style('width'));
  ratio = 1;
  if (window.innerWidth <= 750) {
    ratio = 1.25;
  }
  test = width * -1;
  svg.select('#zentralschweiz').attr("transform", "scale(" + ratio + "), translate(" + this.regions['Zentralschweiz'].origin + ")");
  svg.select('#mittelland').attr("transform", "scale(" + ratio + "), translate(" + this.regions['Mittelland'].origin + ")");
  svg.select('#ostschweiz').attr("transform", "scale(" + ratio + "), translate(" + this.regions['Ostschweiz'].origin + ")");
  svg.select('#westschweiz').attr("transform", "scale(" + ratio + "), translate(" + this.regions['Westschweiz'].origin + ")");
};

d3.select(window).on('resize', resize);

windowWidth = window.innerWidth;

if (windowWidth <= 750) {
  console.log('Mobile');
}

this.regions = [];

this.regions[0] = '1';

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
  }), (function(_this) {
    return function(err, data1) {
      var switzerland;
      _this.data = data1;
      if (err) {
        return console.error(err);
      }
      console.log('Step 2 - load my data', data);
      switzerland = topojson.feature(geojson_switzerland, geojson_switzerland.objects.cantons);
      console.log(switzerland);
      d3.json('regions.json', function(err, regions) {
        var height, key, mittelland, ostschweiz, path, ref, region, svg, westschweiz, width, zentralschweiz;
        if (err) {
          return console.error(err);
        }
        this.region_names = [];
        this.all_regions = regions.regions;
        ref = this.all_regions;
        for (key in ref) {
          region = ref[key];
          this.region_names.push(region.name);
          this.regions[region.name] = {
            features: [],
            color: region.color,
            origin: region.origin
          };
        }
        this.data.forEach((function(_this) {
          return function(row) {
            return switzerland.features.some(function(canton) {
              var i, k, len, rcanton, ref1, results;
              if (canton.properties.abbr === row.canton) {
                for (k in row) {
                  canton.properties[k] = row[k];
                }
                ref1 = _this.all_regions;
                results = [];
                for (i = 0, len = ref1.length; i < len; i++) {
                  region = ref1[i];
                  results.push((function() {
                    var j, len1, ref2, results1;
                    ref2 = region.cantons;
                    results1 = [];
                    for (j = 0, len1 = ref2.length; j < len1; j++) {
                      rcanton = ref2[j];
                      if (rcanton.name === row.canton) {
                        canton.properties['region'] = region.name;
                        results1.push(this.regions[region.name].features.push(canton));
                      } else {
                        results1.push(void 0);
                      }
                    }
                    return results1;
                  }).call(_this));
                }
                return results;
              }
            });
          };
        })(this));
        console.log(this.regions);
        console.log('Step 3 - Check resulting dataset', switzerland);
        svg = d3.select('svg');
        width = parseInt(d3.select('svg').style('width'));
        height = parseInt(d3.select('svg').style('height'));
        path = d3.geo.path().projection(null);
        console.log('features');
        console.log(switzerland.features);
        console.log(this.regions);
        westschweiz = svg.select('#westschweiz').selectAll('path.canton').data(this.regions['Westschweiz'].features).enter().append('path').attr('class', 'canton').attr('d', path).style('fill', this.regions['Westschweiz'].color).style('stroke', 'white').attr('stroke-width', 1);
        ostschweiz = svg.select('#ostschweiz').selectAll('path.canton').data(this.regions['Ostschweiz'].features).enter().append('path').attr('class', 'canton').attr('d', path).style('fill', this.regions['Ostschweiz'].color).style('stroke', 'white').attr('stroke-width', 1);
        zentralschweiz = svg.select('#zentralschweiz').selectAll('path.canton').data(this.regions['Zentralschweiz'].features).enter().append('path').attr('class', 'canton').attr('d', path).style('fill', this.regions['Zentralschweiz'].color).style('stroke', 'white').attr('stroke-width', 1);
        mittelland = svg.select('#mittelland').selectAll('path.canton').data(this.regions['Mittelland'].features).enter().append('path').attr('class', 'canton').attr('d', path).style('fill', this.regions['Mittelland'].color).style('stroke', 'white').attr('stroke-width', 1);
        d3.selectAll('g').style("display", "none");
        return resize();
      });
    };
  })(this));
});


