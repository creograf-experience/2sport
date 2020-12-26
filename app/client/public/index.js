import _ from 'lodash';

import {initMap, drawPath, drawChart} from './lib/workout';
import {drawChartInstagram} from './lib/workout-instagram';

const {track} = window.BACKEND_DATA;
const trackTimeline = _.map(track, 4);
const coeffs = {kmph: 3.6};
const trackSpeedKmph = _.map(track, p => {
  return p[8] * coeffs.kmph;
});

const map = initMap('map');
drawPath(map, track);

console.log(location.href.indexOf('?nolayout=true') > -1);
if (location.href.indexOf('?nolayout=true') > -1 ) {
  drawChartInstagram('#speed-graph', trackTimeline, trackSpeedKmph);
  drawChartInstagram('#height-graph', trackTimeline, _.map(track, 6));
}
else {
  drawChart('#speed-graph', trackTimeline, trackSpeedKmph);
  drawChart('#height-graph', trackTimeline, _.map(track, 6));
}