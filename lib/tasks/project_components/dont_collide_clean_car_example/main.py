#!/bin/python3

# Import library code
from p5 import *
from random import randint, seed

level = 1
score = 0

# The draw_obstacle function goes here
def draw_obstacles():
    global level
    
    seed(123456789)
    
    if frame_count % width == width - 1 and level < 10:
        level += 1
        print('You reached level', level)
      
    for i in range(6 + level):
        ob_x = randint(0, width) - (frame_count * level)
        ob_y = randint(0, height) 
        ob_x %= width  # wrap around
        text('💩', ob_x, ob_y)
    
# The draw_player function goes here
def draw_player():
    global score, level
    
    player_x = int(width * 0.2)
    player_y = mouse_y
    
    collide = get(player_x + 50, player_y + 15).hex
    collide2 = get(player_x + 50, player_y - 15).hex
    collide3 = get(player_x, player_y + 15).hex
    collide4 = get(player_x, player_y - 15).hex
    collide5 = get(player_x - 50, player_y + 15).hex
    collide6 = get(player_x - 50, player_y - 15).hex
    
    if player_y > height - 18:  # Off the bottom of the screen
        collide = safe.hex
        collide3 = safe.hex
        collide5 = safe.hex
      
    elif player_y < 18:  # Off the top of the screen
        collide2 = safe.hex
        collide4 = safe.hex
        collide6 = safe.hex
      
    if collide == safe.hex and collide2 == safe.hex and collide3 == safe.hex and collide4 == safe.hex:
        image(car, player_x, player_y, 100, 31)
        score += level
    else:
        text('💥', player_x, player_y)
        level = 0


def setup():
    # Setup your animation here
    size(400, 400)
    global car
    car = load_image('car.png')
    image_mode(CENTER)
  
  
def draw():
    # Things to do in every frame
    global score, safe, level
    safe = Color(128)
    
    if level > 0:
        background(safe)
        fill(255)
        text_size(16)
        text_align(RIGHT, TOP)
        text('Score', width * 0.45, 10, width * 0.5, 20)
        text(str(score), width * 0.45, 25, width * 0.5, 20)
        text_size(20)
        text_align(CENTER, TOP)  # position around the centre, top
        draw_obstacles()
        draw_player()
  
run()
