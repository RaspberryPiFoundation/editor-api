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
                'region': info[0],
                'population': int(info[1]),
                'population density': float(info[2]),
                'median age': float(info[3]),
                'percentage urban': float(info[4])
            }
            #print(region_dict)
            region_list.append(region_dict)

def draw_pin(x, y, colour):
    no_stroke()
    fill(colour)
    rect(x, y, 7, 7)


def draw_data():
    global colours
    colours = {}
    red_value = 255
    for region in region_list:
        if answer == 'u' and region['percentage urban'] >= 50.0:
            region_name = region['region']
            region_coords = get_region_coords(region_name)
            region_x = region_coords['x']
            region_y = region_coords['y']
            region_colour = Color(red_value, 255, 0)
            draw_pin(region_x, region_y, region_colour)
            colours[region_colour.hex] = region
            red_value -= 1
        elif answer == 'r' and region['percentage urban'] < 50.0:
            region_name = region['region']
            region_coords = get_region_coords(region_name)
            region_x = region_coords['x']
            region_y = region_coords['y']
            region_colour = Color(red_value, 255, 0)
            draw_pin(region_x, region_y, region_colour)
            colours[region_colour.hex] = region
            red_value -= 1
  

def preload():
    global map
    map = load_image('mercator_bw.png')


def setup():
    # Put code to run once here
    size(991, 768)
    load_data('pop.csv')
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
        print('Population: ', str(info['population']))
        print('Population density: ', str(info['population density']))
        print('Average age: ', str(info['median age']))
        print('Percentage urban: ', str(info['percentage urban']))

answer = None

while answer not in ['u', 'r']:
    answer = input('Please enter u to see places that are mostly urban, or r to see places that are mostly rural: ')


run()
