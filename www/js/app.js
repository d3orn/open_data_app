var addEventListner, combineData, draw, drawRegion, loadData, loadJSON, loadRegions, loadSwitzerland, resize, show, tip, tooltipHide, tooltipShow, update, updateFields, windowWidth;

this.years = [2010, 2011, 2012, 2013, 2014];

this.year = 2014;

this.field = 'Informatik';

this.type = 'EFZ';

this.gender = 'both';

this.value = 'total';

this.regions = [];

this.active = 'Westschweiz';

this.cantonsObjects = {
  'ZH': {},
  'BE': {},
  'LU': {},
  'UR': {},
  'SZ': {},
  'OW': {},
  'NW': {},
  'GL': {},
  'ZG': {},
  'FR': {},
  'SO': {},
  'BS': {},
  'BL': {},
  'SH': {},
  'AR': {},
  'AI': {},
  'SG': {},
  'GR': {},
  'AG': {},
  'TG': {},
  'TI': {},
  'VD': {},
  'VS': {},
  'NE': {},
  'GE': {},
  'JU': {}
};

this.svg = d3.select('svg');

tip = d3.select("body").append("div").attr("class", "tip").style("opacity", 0);

windowWidth = window.innerWidth;

$('.right-small').click(function() {
  return $('.off-canvas-wrap').foundation('offcanvas', 'show', 'move-left');
});

$(document).ready((function(_this) {
  return function() {
    var dataCounter, index, ref, year;
    dataCounter = 0;
    ref = _this.years;
    for (index in ref) {
      year = ref[index];
      $('#year').append($('<option/>', {
        value: year,
        text: year
      }));
    }
    return loadJSON().then(function() {
      return loadSwitzerland().then(function() {
        return loadRegions().then(function() {
          return draw();
        });
      });
    });
  };
})(this));

loadJSON = function() {
  var deffered;
  deffered = jQuery.Deferred();
  d3.json("10-14.json.gz", function(d) {
    console.log(d);
    this.cantonsObjects = d;
    return deffered.resolve();
  });
  return deffered.promise();
};

loadData = function(year) {
  var deffered;
  deffered = jQuery.Deferred();
  d3.csv(year + ".csv", function(d) {
    var field, obj, type;
    field = d.Ausbildungsfeld;
    type = d.Ausbildungstyp;
    obj = this.cantonsObjects[d.Canton];
    if (obj) {
      if (!obj[year]) {
        obj[year] = {};
      }
      if (!obj[year][field]) {
        obj[year][field] = {};
      }
      if (!obj[year][field][type]) {
        obj[year][field][type] = {
          both: {},
          men: {},
          women: {}
        };
      }
      obj[year][field][type].both = {
        total: d.Geschlecht_Total,
        dual: d.Geschlecht_Dual,
        full: d.Geschlecht_Vollschulisch
      };
      obj[year][field][type].women = {
        total: d.Frau_Total,
        dual: d.Frau_Dual,
        full: d.Frau_Vollschulisch
      };
      return obj[year][field][type].men = {
        total: d.Mann_Total,
        dual: d.Mann_Dual,
        full: d.Mann_Vollschulisch
      };
    }
  }, function() {
    return deffered.resolve();
  });
  return deffered.promise();
};

loadSwitzerland = function() {
  var deffered;
  deffered = jQuery.Deferred();
  d3.json('ch.json', (function(_this) {
    return function(err, geojson_switzerland) {
      if (err) {
        return console.error(err);
      }
      _this.switzerland = topojson.feature(geojson_switzerland, geojson_switzerland.objects.cantons);
      return deffered.resolve();
    };
  })(this));
  return deffered.promise();
};

loadRegions = function() {
  var deffered;
  deffered = jQuery.Deferred();
  d3.json('regions.json', function(err, regions) {
    var key, ref, region, region_names;
    if (err) {
      return console.error(err);
    }
    region_names = [];
    this.all_regions = regions.regions;
    ref = this.all_regions;
    for (key in ref) {
      region = ref[key];
      region_names.push(region.name);
      this.regions[region.name] = {
        features: [],
        color: region.color,
        origin: region.origin,
        width: region.origWidth,
        height: region.origHeight
      };
    }
    return deffered.resolve();
  });
  return deffered.promise();
};

draw = function() {
  var name;
  combineData();
  this.path = d3.geo.path().projection(null);
  for (name in this.regions) {
    drawRegion(name);
  }
  updateFields();
  update();
  resize();
  d3.selectAll('g').style("display", "none");
  this.svg.select('#Westschweiz').style("display", "block");
  return addEventListner();
};

addEventListner = function() {
  var that;
  d3.select(window).on('resize', resize);
  this.svg.selectAll('path.canton').on('mousedown', tooltipShow).on('mouseover', tooltipShow).on('click', tooltipShow).on('mouseup', tooltipHide).on('mouseout', tooltipHide);
  this.svg.selectAll('text').on('mousedown', tooltipShow).on('mouseover', tooltipShow).on('click', tooltipShow).on('mouseup', tooltipHide).on('mouseout', tooltipHide);
  that = this;
  $('#year').change(function() {
    that.year = $(this).val();
    updateFields();
    return update();
  });
  $('#field').change(function() {
    that.field = $(this).val();
    return update();
  });
  $('#type').change(function() {
    that.type = $(this).val();
    return update();
  });
  return $('#gender').change(function() {
    that.gender = $(this).val();
    return update();
  });
};

combineData = function() {
  var data, item, key, ref, results, year;
  ref = this.cantonsObjects;
  results = [];
  for (key in ref) {
    item = ref[key];
    results.push((function() {
      var results1;
      results1 = [];
      for (year in item) {
        data = item[year];
        results1.push(this.switzerland.features.some((function(_this) {
          return function(canton) {
            var j, len, rcanton, ref1, region, results2;
            if (canton.properties.abbr === key) {
              canton.properties[year] = data;
              ref1 = _this.all_regions;
              results2 = [];
              for (j = 0, len = ref1.length; j < len; j++) {
                region = ref1[j];
                results2.push((function() {
                  var k, len1, ref2, results3;
                  ref2 = region.cantons;
                  results3 = [];
                  for (k = 0, len1 = ref2.length; k < len1; k++) {
                    rcanton = ref2[k];
                    if (rcanton.name === key) {
                      canton.properties['region'] = region.name;
                      results3.push(this.regions[region.name].features.push(canton));
                    } else {
                      results3.push(void 0);
                    }
                  }
                  return results3;
                }).call(_this));
              }
              return results2;
            }
          };
        })(this)));
      }
      return results1;
    }).call(this));
  }
  return results;
};

drawRegion = (function(_this) {
  return function(regionName) {
    var features;
    features = _this.regions[regionName].features;
    _this.svg.select("#" + regionName).selectAll('path.canton').data(features).enter().append('path').attr('class', 'canton').attr('d', _this.path).style('fill', _this.regions[regionName].color).style('stroke', 'white').attr('stroke-width', 1);
    return _this.svg.select("#" + regionName).selectAll('text').data(features).enter().append('g').attr('class', 'text').attr('transform', function(d) {
      var center;
      center = path.centroid(d);
      center[0] = center[0] - 5;
      return 'translate(' + center + ')';
    }).append('text').style('fill', '#FFF').text(function(d) {
      return d.properties.abbr;
    });
  };
})(this);

update = function() {
  var color, feature, features, j, len, max, min, name, ref, region, results, scale, value;
  ref = this.regions;
  results = [];
  for (name in ref) {
    region = ref[name];
    features = region.features;
    max = 0;
    min = 0;
    for (j = 0, len = features.length; j < len; j++) {
      feature = features[j];
      value = parseInt(feature.properties[this.year][this.field][this.type][this.gender][this.value]);
      if (value >= max) {
        max = value;
      }
      if (value <= min) {
        min = value;
      }
    }
    color = d3.rgb(region.color);
    scale = d3.scale.quantize().domain([min, max]).range([color.brighter(3), color.brighter(1), color, color.darker(1), color.darker(3)]);
    if (min === max) {
      scale = function(int) {
        return color.brighter(3);
      };
    }
    if (name === this.active) {
      $('#scale').children().each(function(index, item) {
        var nextStep, step;
        step = max / 5 * index;
        nextStep = max / 5 * (index + 1);
        if (step === nextStep) {
          $(item).find('.box').css("background-color", scale(step));
          $(item).find('.content').html("<p>" + (parseInt(step)) + "</p>");
          $('#scale li').not(item).hide();
          return false;
        } else {
          $(item).show();
          $(item).find('.box').css("background-color", scale(step));
          return $(item).find('.content').html("<p>" + (parseInt(step)) + " - " + (parseInt(nextStep)) + "</p>");
        }
      });
    }
    results.push(this.svg.select("#" + name).selectAll('path.canton').data(features).style('fill', (function(_this) {
      return function(d) {
        value = parseInt(d.properties[_this.year][_this.field][_this.type][_this.gender][_this.value]);
        return d3.rgb(scale(value));
      };
    })(this)));
  }
  return results;
};

updateFields = function() {
  var field, fields;
  fields = this.cantonsObjects['BE'][year];
  for (field in fields) {
    $('#field').append($('<option/>', {
      value: field,
      text: field
    }));
  }
  $("[data-region=" + this.active + "]").addClass('active');
  $("#year").val(this.year);
  $("#field").val(this.field);
  $("#type").val(this.type);
  return $("#gender").val(this.gender);
};

show = function(elem) {
  var region;
  $(elem).addClass('active');
  $('.button').not(elem).removeClass('active');
  region = elem.getAttribute('data-region');
  this.active = region;
  d3.selectAll('g').style("display", "none");
  this.svg.select('#' + region).style("display", "block");
  return update();
};

resize = function() {
  var height, heightRatio, name, ratio, ref, region, width, widthRatio;
  width = parseInt(svg.style('width')) - 15;
  height = parseInt(svg.style('height')) - 15;
  ref = this.regions;
  for (name in ref) {
    region = ref[name];
    widthRatio = width / parseInt(region.width);
    heightRatio = height / parseInt(region.height);
    ratio = Math.min(widthRatio, heightRatio);
    this.svg.select("#" + name).attr("transform", "scale(" + ratio + "), translate(" + region.origin + ")");
  }
};

tooltipShow = (function(_this) {
  return function(d, i) {
    var data, name, value;
    data = d.properties;
    value = data[_this.year][_this.field][_this.type][_this.gender][_this.value];
    name = data.name.replace('Ã¨', 'è').replace('Ã¢', 'â').replace('Ã¼', 'ü');
    tip.transition().duration(200).style('opacity', .9);
    return tip.html("<h5>" + name + "</h5> <p>" + _this.field + " / " + _this.type + "</p> <p>" + value + "</p>").style("left", d3.event.pageX + "px").style("top", (d3.event.pageY - 28) + "px");
  };
})(this);

tooltipHide = function() {
  return tip.transition().duration(500).style('opacity', 0);
};


