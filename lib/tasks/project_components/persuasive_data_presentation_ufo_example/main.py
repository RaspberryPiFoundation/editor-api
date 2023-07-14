#!/bin/python3
from p5 import *

from xy import get_xy_coords

# Draw the UFO on the map
def draw_ufo(shape, x, y):
  
    global fireball, circle, tri, light, disk, misc, cylinder
    fireball = Color(252, 186, 3)  
    circle = Color(32, 201, 49)  
    tri = Color(241, 245, 32)  
    light = Color(247, 247, 245)  
    disk = Color(189, 189, 172)  
    misc = Color(255, 0, 0)
    cylinder = Color(73, 99, 230)
    
    if shape == 'fireball':
        fill(fireball)
        ellipse(x, y, 15, 10)
    elif shape == 'circle':
        fill(circle)
        ellipse(x, y, 8, 8)
    elif shape == 'triangle':
        fill(tri)
        triangle(x-8, y-15, x, y, x+8, y-15)
    elif shape == 'light':
        fill(light)
        ellipse(x, y, 15, 15)
    elif shape == 'disk':
        fill(disk)
        ellipse(x, y, 20, 10)
    elif shape == 'cylinder' or shape == 'cigar':
        fill(cylinder)
        rect(x, y, 20, 10)
    else:
        fill(misc)
        ellipse(x, y, 10, 10)

def setup():
  
    size(991, 768)
    global map
    map = load_image('mercator.jpeg')
    load_data('ufo-sightings.csv')

def load_data(file_name):
  
    # Create a dictionary for each siting based on the data in the csv file
    
    global ufo_sightings
    
    ufo_sightings = []
    
    with open(file_name) as f:
        for line in f:
            info = line.split(',')
            ufo_dict = {
                'date': info[0],
                'time': info[1],
                'state': info[2],
                'country': info[3],
                'shape': info[4],
                'duration': info[5],
                'latitude': info[6],
                'longitude': info[7]
            }
            ufo_sightings.append(ufo_dict) # Store dictionary in a list

def draw_data():
  
    # Use the lat and long data to calculate the x y coords for the shape
    
    for sighting in ufo_sightings:
    
        longitude = float(sighting['longitude'])
        latitude = float(sighting['latitude'])
        
        region_coords = get_xy_coords(longitude, latitude)
        
        region_x = region_coords['x']
        region_y = region_coords['y']
        
        shape = sighting['shape']
        
        draw_ufo(shape, region_x, region_y)

def draw():

    image(
        map, # The image to draw
        0, # The x of the top-left corner
        0, # The y of the top-left corner
        width, # The width of the image
        height # The height of the image
    )
    draw_data()


def mouse_pressed():
  
    # Display a message depending on what shape the user has pressed
    
    pixel_colour = Color(get(mouse_x, mouse_y)).hex
    if pixel_colour == fireball.hex:
        print('A fireball UFO was spotted here!')
    elif pixel_colour == circle.hex:
        print('A circle shaped UFO was spotted here!')
    elif pixel_colour == tri.hex:
        print('A triangle shaped UFO was spotted here!')
    elif pixel_colour == light.hex:
        print('A UFO made of light was spotted here!')
    elif pixel_colour == disk.hex:
        print('A disk shaped UFO was spotted here!')
    elif pixel_colour == misc.hex:
        print('A random shaped UFO was spotted here!')
    elif pixel_colour == cylinder.hex:
        print('A cylinder shaped UFO was spotted here!')
    else:
        print('There were no UFO sightings in this area!')
  
run()
