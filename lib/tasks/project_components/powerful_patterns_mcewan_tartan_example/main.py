#!/bin/python3

from p5 import *

def setup():
  size(400, 400)
  frame_rate(10)
  print('🏴󠁧󠁢󠁳󠁣󠁴󠁿󠁢󠁳󠁣󠁴󠁿 This is McEwen Tartan 🏴󠁧󠁢󠁳󠁣󠁴󠁿󠁧󠁢󠁳󠁣󠁴󠁿')
 
  global square_size
  square_size = int(input('What size 🏴󠁧󠁢󠁳󠁣󠁴󠁿tartan would you like? 20, 50, or 100'))
  
def draw():
  
  lines = 10 * frame_count # Use in shape width/length to animate over time
  
  # McEwen tartan colours
  # Base square colours
  BLUE = color(83, 143, 200)
  GREEN = color(78, 163, 162)
  BASE_COLORS = [GREEN, BLUE]
  
  # Cross colours
  YELLOW = color(155, 176, 135)
  RED = color(155, 129, 113)
  CROSS_COLORS = [YELLOW, RED]
  
  # Stitching and overlap colour
  GREY = color(78, 99, 86)
  
  # Draw all the GREEN and BLUE alternating Base squares
  no_stroke()
  y_coordinate = 0
  squares = width/square_size
  
  for i in range (int(squares)):
    gap = 0
    for j in range (int(squares)):
      fill(BASE_COLORS[j % 2]) # GREEN and BLUE 
      rect(gap, y_coordinate, square_size, square_size)
      gap = gap + square_size
    y_coordinate = y_coordinate + square_size
  
  # Crosses
  stroke(GREY)
 
  # DRAW THE YELLOW and RED alternating crosses
  for i in range (4):
    fill(YELLOW)
    cross = square_size / 2 - 2 
    for i in range (int(squares/2)):
      fill(CROSS_COLORS[i % 2]) # YELLOW and RED
      rect(cross, 0, 4, lines)  
      rect(0, cross, lines, 4) 
      cross = cross + 2 * square_size
    # Draw the stiching crosses
    no_fill() 
    cross = square_size + square_size / 2 - 2
    for i in range (int(squares)): 
      rect(cross, 0, 4, lines) 
      rect(0, cross, lines, 4)
      cross = cross + square_size

  # Draw the grey lines where material overlaps
  no_stroke()
  fill(GREY, 100)
  gap = square_size - 4
  for i in range (int(squares)):
    rect(gap, 0, 8, lines)
    gap = gap + square_size
  gap = square_size - 4
  for i in range (int(squares)):
    rect(0, gap, lines, 8)
    gap = gap + square_size
  
run()



