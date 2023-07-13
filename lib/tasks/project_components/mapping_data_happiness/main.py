#!/bin/python3
from p5 import *
from regions import get_region_coords
from random import randint

region_list = []
colours = {}


def setup():
# Put code to run once here
  global map
  load_data('happy.csv')
  size(991, 768)
  map = load_image('tech_map.jpg')
 

def draw():
# Put code to run every frame here
  image(
    map,  # The image to draw
    0,  # The x of the top-left corner
    0,  # The y of the top-left corner
    width,  # The width of the image
    height  # The height of the image
    )
  draw_data()


def mouse_pressed():
# Put code to run when the mouse is pressed here
  pixel_colour = Color(get(mouse_x, mouse_y)).hex
  if pixel_colour in colours:
    facts = colours[pixel_colour]
    print(facts['name'])
    print(facts['happiness rank'])
  else:
    print('Region not detected')
    

def load_data(file_name):
  with open(file_name) as f:
    for line in f:
      #print(line)
      info = line.split(',')
      region_dict = {
        'name': info[0],
        'happiness rank': int(info[1]),
        'happiness score': float(info[2])
      }
      #print(region_dict)
      region_list.append(region_dict)


def draw_pin(x, y, colour):
  no_stroke()
  fill(colour)
  ellipse(x, y, 10, 10)


def draw_data():
  i = 255
  for region in region_list:
    region_name = region['name']  # Get the name of the region
    region_coords = get_region_coords(region_name)  # Use the name to get coordinates
    region_x = region_coords['x']  # Get the x coordinate
    region_y = region_coords['y']  # Get the y coordinate
    region_colour = Color(i, 100, 0)  # Set the pin colour
    colours[region_colour.hex] = region
    draw_pin(region_x, region_y, region_colour)
    i -= 1

   
run()
