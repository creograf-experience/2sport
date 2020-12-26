const _ = require('lodash');
const clustering = require('density-clustering');

module.exports = {
  distance,
  midpoint,
  clusterize,
  minDistanceBetweenClusters
};

function deg2rad(deg) {
  return deg * (Math.PI/180);
}

function rad2deg(rad) {
  return rad * (180/Math.PI);
}

/**
 * distance in meters between two [lon, lat] pairs
 * @param  {Array} p1 [lon, lat]
 * @param  {Array} p2 [lon, lat]
 * @return {Number} meters
 */
function distance(p1, p2) {
  const R = 6371 * 1000;
  const dLon = deg2rad(p1[0] - p2[0]);
  const dLat = deg2rad(p1[1] - p2[1]);
  const a =
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(deg2rad(p1[0])) * Math.cos(deg2rad(p2[0])) *
    Math.sin(dLon/2) * Math.sin(dLon/2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  const d = R * c;
  return d;
}

/**
 * finds the median point for a passed array
 * of [lon, lat] points
 * @param  {Array[]} points [[lon, lat]]
 * @return {Array} [lon, lat]
 */
function midpoint(points) {
  const n = points.length;

  const pointsRad = points.map(point => {
    return [
      deg2rad(point[0]),
      deg2rad(point[1])]
  });

  const X = pointsRad.map(point => {
    return Math.cos(point[0]) * Math.cos(point[1]);
  });
  const Y = pointsRad.map(point => {
    return Math.cos(point[0]) * Math.sin(point[1]);
  });
  const Z = pointsRad.map(point => {
    return Math.sin(point[0]);
  });

  const x = _.sum(X) / n;
  const y = _.sum(Y) / n;
  const z = _.sum(Z) / n;

  const lon = Math.atan2(y, x);
  const hyp = Math.sqrt(x * x + y * y);
  const lat = Math.atan2(z, hyp);

  return [rad2deg(lat), rad2deg(lon)];
}

function mapClustersToData (data, cluster) {
  return cluster.map((i) => data[i]);
}

/**
 * group points into clusters using DBSCAN algorythm,
 * using distance function that calcs meters between [lon, lat]
 * @param  {Array[]} dataset [[lon, lat]]
 * @return {Array[][]} clusters [[[lon, lat]]]
 */
function clusterize(dataset) {
  const dbscan = new clustering.DBSCAN();
  const clusters = dbscan.run(dataset, 150, 3, distance);

  return clusters.map(_.partial(mapClustersToData, dataset));
}

function minDistanceBetweenClusters (C1, C2) {
  return _.min(C1.map(c1 => {
    return _.min(C2.map(c2 => {
      if (c1.activity == c2.activity) {
        return distance(c1.location, c2.location);
      } else {
        return Infinity;
      }
    }));
  }));
}
