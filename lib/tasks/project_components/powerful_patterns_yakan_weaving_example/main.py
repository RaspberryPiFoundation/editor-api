#!/bin/python3

import py5

def motif():
  motif_size = 100

  #Thread colours
  ORANGE = py5.color(254, 96, 1)
  PURPLE = py5.color(135, 18, 192)
  YELLOW = py5.color(243, 200, 19)
  BLUE = py5.color(83, 171, 176)

  # Squares
  py5.fill(ORANGE)
  py5.rect(0, 0, motif_size/2, motif_size/2)
  py5.fill(PURPLE)
  py5.rect(50, 0, motif_size/2, motif_size/2)
  py5.fill(YELLOW)
  py5.rect(0, 50, motif_size/2, motif_size/2)
  py5.fill(BLUE)
  py5.rect(50, 50, motif_size/2, motif_size/2)
  py5.fill(PURPLE)
  py5.rect(0, 0, motif_size/4, motif_size/4)
  py5.fill(ORANGE)
  py5.rect(50, 0, motif_size/4, motif_size/4)
  py5.fill(BLUE)
  py5.rect(0, 50, motif_size/4, motif_size/4)
  py5.fill(YELLOW)
  py5.rect(50, 50, motif_size/4, motif_size/4)

def rotate_motif():

  for shape in range(5): # row of shapes
    py5.push_matrix() # save settings
    py5.rotate(py5.radians(45)) # turn shape 45 degrees
    motif()
    py5.pop_matrix() # go back to saved settings
    py5.translate(motif_width, 0) # move horizontally

def setup():
  py5.size(400, 400)
  py5.frame_rate(3)
  py5.background(250, 5, 94) # pink
  py5.no_stroke()
  print('This is 🇵🇭 Yakan weaving ')

def draw():

  global motif_width
  motif_width = 150

  py5.translate(-motif_width/2, -motif_width/2) # to start with half motifs

  if py5.frame_count < 20: # maximum rows
    for row in range(py5.frame_count):
      rotate_motif()
      if row / 2 == 0: # to offset pattern on next row
        py5.translate(-motif_width * 5 + 75, 80)
      else:
        py5.translate(-motif_width * 5 - 75, 80)

py5.run_sketch()
