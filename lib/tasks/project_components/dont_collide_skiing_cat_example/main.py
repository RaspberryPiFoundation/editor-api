#!/bin/python3

# Import library code
from p5 import *
from random import randint, seed

speed = 1
score = 0

# The draw_background function goes here
def draw_obstacles():
    global speed
    
    seed(12345678)
    
    if frame_count % height == height - 1 and speed < 5:
        speed += 1
        print('You reached level', speed)
      
    for i in range(6):
        ob_x = randint(0, height)
        ob_y = randint(0, height) + (frame_count * speed)
        ob_y %= height  # wrap around
        no_stroke()
        fill(0,255,0)
        triangle(ob_x + 20, ob_y + 20, ob_x + 10, ob_y + 40, ob_x + 30, ob_y + 40)
        triangle(ob_x + 20, ob_y + 30, ob_x + 5, ob_y + 55, ob_x + 35, ob_y + 55)
        triangle(ob_x + 20, ob_y + 40, ob_x + 0, ob_y + 70, ob_x + 40, ob_y + 70)
        fill(150,100,100)
        rect(ob_x + 15, ob_y + 70, 10, 10)
    
# The draw_player function goes here
def draw_player():
    global score, speed, skiing, crashed
    
    player_y = int(height * 0.8)
    
    fill(safe)
  
    collide = get(mouse_x, player_y).hex
    
    if collide == safe.hex:
        image(skiing, mouse_x, player_y, 30, 30)
        score += speed
    else:
        image(crashed, mouse_x, player_y, 30, 30)
        speed = 0
    
  
def setup(): 
    # Setup your animation here
    size(400, 400)
    text_size(40)
    text_align(CENTER, TOP)  # position around the centre
    global skiing, crashed
    skiing = load_image('skiing.png')
    crashed = load_image('fallenover.png')
  
def draw():
    # Things to do in every frame
    global score, safe, speed, skiing, crashed
    safe = Color(255)
  
    if speed > 0:
        background(safe) 
        fill(0)
        text('Score: ' + str(score), width/2, 20)
        draw_obstacles()
        draw_player()
  
run()
