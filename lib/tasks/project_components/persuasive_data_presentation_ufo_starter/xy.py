#!/bin/python3
from math import radians, pi, log, tan

def convert_lat_long(latitude, longitude, map_width, map_height):
  
  false_easting = 180
  radius = map_width / (2 * pi)
  latitude = radians(latitude)
  longitude = radians(longitude + false_easting)
  
  x_coord = longitude * radius
  
  y_dist_from_equator = radius * log(tan(pi / 4 + latitude / 2))
  y_coord = map_height / 2 - y_dist_from_equator
  
  coords = {'x': x_coord, 'y': y_coord}
  
  return coords


def get_xy_coords(longitude, latitude, map_width=991, map_height=768):
  
  coords = None
  
  coords = convert_lat_long(latitude, longitude, map_width, map_height)
  return coords
