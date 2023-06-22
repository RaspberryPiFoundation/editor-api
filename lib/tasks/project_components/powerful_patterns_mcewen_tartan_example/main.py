#!/bin/python3

import py5

def setup():
  py5.size(400, 400)
  py5.frame_rate(10)
  
def draw():
  
  lines = 10 * py5.frame_count # Use in shape py5.width/length to animate over time
  
  # McEwen tartan colours
  # Base square colours
  BLUE = py5.color(83, 143, 200)
  GREEN = py5.color(78, 163, 162)
  BASE_COLORS = [GREEN, BLUE]
  
  # Cross colours
  YELLOW = py5.color(155, 176, 135)
  RED = py5.color(155, 129, 113)
  CROSS_COLORS = [YELLOW, RED]
  
  # Stitching and overlap colour
  GREY = py5.color(78, 99, 86)
  
  # Draw all the GREEN and BLUE alternating Base squares
  py5.no_stroke()
  y_coordinate = 0
  squares = py5.width/square_size
  
  for i in range (int(squares)):
    gap = 0
    for j in range (int(squares)):
      py5.fill(BASE_COLORS[j % 2]) # GREEN and BLUE 
      py5.rect(gap, y_coordinate, square_size, square_size)
      gap = gap + square_size
    y_coordinate = y_coordinate + square_size
  
  # Crosses
  py5.stroke(GREY)
 
  # DRAW THE YELLOW and RED alternating crosses
  for i in range (4):
    py5.fill(YELLOW)
    cross = square_size / 2 - 2 
    for i in range (int(squares/2)):
      py5.fill(CROSS_COLORS[i % 2]) # YELLOW and RED
      py5.rect(cross, 0, 4, lines)  
      py5.rect(0, cross, lines, 4) 
      cross = cross + 2 * square_size
    # Draw the stiching crosses
    py5.no_fill() 
    cross = square_size + square_size / 2 - 2
    for i in range (int(squares)): 
      py5.rect(cross, 0, 4, lines) 
      py5.rect(0, cross, lines, 4)
      cross = cross + square_size

  # Draw the grey lines where material overlaps
  py5.no_stroke()
  py5.fill(GREY, 100)
  gap = square_size - 4
  for i in range (int(squares)):
    py5.rect(gap, 0, 8, lines)
    gap = gap + square_size
  gap = square_size - 4
  for i in range (int(squares)):
    py5.rect(0, gap, lines, 8)
    gap = gap + square_size

print('🏴󠁧󠁢󠁳󠁣󠁴󠁿󠁢󠁳󠁣󠁴󠁿 This is McEwen Tartan 🏴󠁧󠁢󠁳󠁣󠁴󠁿󠁧󠁢󠁳󠁣󠁴󠁿')
square_size = int(input('What size 🏴󠁧󠁢󠁳󠁣󠁴󠁿tartan would you like? 20, 50, or 100'))
  
py5.run_sketch()



