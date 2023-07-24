#!/bin/python3
from p5 import *
from random import randint

pt_dict = {}
pt_dict_group = {}
pt_dict_period = {}

# Put code to run once here
def setup():
    global map
    load_pt_data('pt.csv')
    setup_coords()
    size(1024, 576)
    map = load_image('pt.png')

def setup_coords():

    for i in range(18):
        pt_dict_group[i + 1] = {}
        pt_dict_group[i + 1]['min_x'] = 25 + (i * 54)
        pt_dict_group[i + 1]['max_x'] = 25 + (i * 54) + 55
    
    for i in range(9):
        pt_dict_period[i + 1] = {}
        pt_dict_period[i + 1]['min_y'] = 35 + (i * 54)
        pt_dict_period[i + 1]['max_y'] = 35 + (i * 54) + 55
      
# Put code to run every frame here
def draw():
    image(
        map, # The image to draw
        0, # The x of the top-left corner
        0, # The y of the top-left corner
        width, # The width of the image
        height # The height of the image
    )

# Put code to run when the mouse is pressed here
def mouse_pressed():
    x_coord = mouse.x
    y_coord = mouse.y
    if y_coord > 415:
        x_coord -= 30
    
    for x in pt_dict_group:
        if pt_dict_group[x]['min_x'] <= x_coord <= pt_dict_group[x]['max_x']:
            group = x
    for y in pt_dict_period:
        if pt_dict_period[y]['min_y'] <= y_coord <= pt_dict_period[y]['max_y']:
            period = y
    for element in pt_dict:
        if pt_dict[element]['group'] == group and pt_dict[element]['period'] == period:
            print(pt_dict[element]['name'], 'is a', pt_dict[element]['appearance'], 'and is a', pt_dict[element]['phase'])
      

def load_pt_data(file_name):
    with open(file_name) as f:
    for line in f:
        info = line.strip().split(',')
        pt_dict[int(info[0])] = {
            'name': info[1],
            'period': int(info[7]),
            'group': int(info[8]),
            'phase': info[9],
            'appearance': info[28]
        }

run()
