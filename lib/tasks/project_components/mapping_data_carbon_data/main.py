#!/bin/python3
from p5 import *
from regions import get_region_coords

region_list = []
colours = {}

# Put code to run once here
def setup():
  load_data('carbon.csv')
  print(region_list)
  size(991, 768)
  map = load_image('mercator_bw.png')
  image(
    map, # The image to draw
    0, # The x of the top-left corner
    0, # The y of the top-left corner
    width, # The width of the image
    height # The height of the image
    )
  #draw_pin(200, 200, color(255,0,0))
  draw_data()

def draw_pin(x, y, colour):
  no_stroke()
  fill(colour)
  triangle(x-10, y-5, x, y+10, x+10, y-5)
  triangle(x-10, y+5, x, y-10, x+10, y+5)

def draw_data():
  red_value = 255 # Set a starting value for red
  blue_value = 0
  green_value = 255
  for region in region_list:
    region_name = region['region'] # Get the name of the region
    region_coords = get_region_coords(region_name) # Use the name to get coordinates
    region_x = region_coords['x'] # Get the x coordinate
    region_y = region_coords['y'] # Get the y coordinate
    #print(region_name, region_x, region_y)
    region_colour = Color(red_value, green_value, blue_value) # Use the red value in the colour
    colours[region_colour] = region
    draw_pin(region_x, region_y, region_colour) # Draw the pin
    red_value -= 1 # Change the red value
    green_value += 1 #Change the green value
    blue_value -= 1 #Change the blue value
  
# Put code to run every frame here
def draw():
  pass


# Put code to run when the mouse is pressed here
def mouse_pressed():
# Put code to run when the mouse is pressed here
  pixel_colour = Color(get(mouse_x, mouse_y))
  if pixel_colour in colours:
    facts = colours[pixel_colour]
    print(facts['region'])
    print(facts['total carbon'])
    print(facts['carbon per person'])
  else:
    print('Region not detected')
  
def load_data(file_name):
  with open(file_name) as f:
    for line in f:
      # print(line)
      info = line.split(',')
      region_dict = {
        'region': info[0],
        'total carbon': info[1],
        'carbon per person': info[2]
      }
      region_list.append(region_dict)
run()
