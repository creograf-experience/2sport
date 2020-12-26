import _ from 'lodash';
import d3 from 'd3';
const {LatLngBounds, LatLng} = google.maps;
window.d3 = d3;
export function initMap(id) {
  var LatLng = google.maps.LatLng;

  return new google.maps.Map(document.getElementById(id), {
    center: {lat: 55.1644420, lng: 61.4368430},
    zoom: 14,
    disableDefaultUI: true
  });
}

export function drawPath(map, track) {
  const coords = track.map(point => {
    return {lat: point[0], lng: point[1]}
  });

  const bounds = new LatLngBounds();
  bounds.extend(new LatLng(_.minBy(coords, 'lat')));
  bounds.extend(new LatLng(_.minBy(coords, 'lng')));
  bounds.extend(new LatLng(_.maxBy(coords, 'lat')));
  bounds.extend(new LatLng(_.maxBy(coords, 'lng')));

  const path = new google.maps.Polyline({
    path: coords,
    geodesic: true,
    strokeColor: '#FF0000',
    strokeOpacity: 1.0,
    strokeWeight: 2
  });

  map.fitBounds(bounds);

  path.setMap(map);
}

export function drawChart(element, times, values) {
  var margin = {top: 20, right: 20, bottom: 30, left: 20},
    width = 465 - margin.left - margin.right,
    height = 180 - margin.top - margin.bottom;

  // Set the ranges
  var x = d3.time.scale()
    .domain(d3.extent(times, d => d))
    .range([0, width]);

  var y = d3.scale.linear()
    .domain([0, _.max(values)])
    .nice(1)
    .range([height, 0]);

  // Define the axes
  var xAxis = d3.svg.axis()
    .scale(x)
    .ticks(5)
    .tickFormat(d3.time.format.utc('%H:%M'))
    .orient("bottom");

  var yAxis = d3.svg.axis()
    .scale(y)
    .orient("right")
    .tickSize(width)
    .ticks(4);

  // Define the line
  var valueline = d3.svg.line()
    .x(d => x(d[0]))
    .y(d => y(d[1]));

  // Adds the svg canvas
  var svg = d3.select(element)
    .append("svg")
      .attr("width", width + margin.left + margin.right)
      .attr("height", height + margin.top + margin.bottom)
    .append("g")
      .attr("transform", `translate(${margin.left},${margin.top})`);

  // Add the valueline path.
  svg.append("path")
    .attr("class", "line")
    .attr("d", valueline(_.zip(times, values)));

  // Add the X Axis
  svg.append("g")
    .attr("class", "x axis")
    .attr("transform", `translate(0,${height})`)
    .call(xAxis);

  // Add the Y Axis
  const gy = svg.append("g")
    .attr("class", "y axis")
    .call(yAxis);

  gy.selectAll("g").filter(d => d)
    .classed("minor", true);

  gy.selectAll("text")
    .attr("x", 4)
    .attr("dy", -4);

}
