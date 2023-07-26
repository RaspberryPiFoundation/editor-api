#!/bin/python3
from p5 import *
from regions import get_region_coords

def load_data(file_name):
    global region_list
    region_list = []

    with open(file_name) as f:
        for line in f:
            #print(line)
            info = line.split(',')
            # Change the dictionary to match the data you're using
            region_dict = {
                'name': info[0],
                'host_count': int(info[1])
            }
            #print(region_dict)
            region_list.append(region_dict)


def preload():
    global map
    map = load_image('mercator.jpeg')


def draw_pin(x, y, colour, host_count):
    no_stroke()
    fill(colour)
    size = 7 + 3 * host_count
    ellipse(x, y, size, size)


def draw_data():
    global colours
    colours = {}
    blue_value = 255

    for region in region_list:
        region_name = region['name']
        region_coords = get_region_coords(region_name)
        region_x = region_coords['x']
        region_y = region_coords['y']
        host_count = region['host_count']
        region_colour = Color(0, 0, blue_value)
        draw_pin(region_x, region_y, region_colour, host_count)
        colours[region_colour.hex] = region
        blue_value -= 1
  
  
def setup():
    # Put code to run once here
    size(991, 768)
    load_data('olympics.csv')
    image(
        map,  # The image to draw
        0,  # The x of the top-left corner
        0,  # The y of the top-left corner
        width,  # The width of the image
        height  # The height of the image
    )
    no_stroke()
    draw_data()

  
def mouse_pressed():
    # Put code to run when the mouse is pressed here
    pixel_colour = Color(get(mouse_x, mouse_y)).hex

    if pixel_colour in colours:
        info = colours[pixel_colour]
        print(info['region'])
        if info['host_count'] == 1:
            print('Hosted the games once.')
        else:
            print('Hosted the games '+str(info['host_count'])+ ' times.')

run()
