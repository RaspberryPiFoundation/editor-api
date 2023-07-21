#!/bin/python3
from p5 import *
from regions import get_region_coords

region_list = []
colours = {}


def draw_pin(x, y, colour):
    fill(colour)
    ellipse(x, y, 10, 10)  # x, y, width, height

def draw_data():
  
    red_value = 255  # Set a starting value for red

    for region in region_list:
        region_name = region['region']  # Get the name of the region
        region_coords = get_region_coords(region_name)  # Use the name to get coordinates
        region_x = region_coords['x']  # Get the x coordinate
        region_y = region_coords['y']  # Get the y coordinate
        #print(region_name, region_x, region_y)
        region_colour = Color(red_value, 0, 0)  # Set the pin colour
        colours[region_colour.hex] = region
        draw_pin(region_x, region_y, region_colour)  # Draw the pin
        red_value -= 1  # Change the red value

# Put code to run once here
def setup():
    size(991, 768)
    load_data('gdp.csv')
    map = load_image('old-map.jpg')  # Replace with your image
    image(
        map,  # The image to draw
        0,  # The x of the top-left corner
        0,  # The y of the top-left corner
        width,  # The width of the image
        height  # The height of the image
    )


# Put code to run every frame here
def draw():
    draw_pin(300, 300, Color(255,0,0))
    draw_data()


# Put code to run when the mouse is pressed here
def mouse_pressed():
    pixel_colour = Color(get(mouse_x, mouse_y)).hex
    if pixel_colour in colours:
        facts = colours[pixel_colour]
        print(facts['region'])
        print(facts['gdp'])
    else:
        print('Region not detected')

def load_data(file_name):
    with open(file_name) as f:
        for line in f:
            #print(line)
            info = line.split(',')
            # Change the dictionary to match the data you're using
            region_dict = {
                'region': info[0],
                'gdp': info[1]
            }
            #print(region_dict)
            region_list.append(region_dict)
            #print(region_list)

run()
