from p5 import *

def grid():
    push_matrix()
    stroke(200)
    fill(0)
    line(0, height/2, width, height/2)
    line(width/2, 0, width/2, height)
    x_coords = [0, width/2, width]
    y_coords = [0, height/2, height]
  
    for x in x_coords:
        for y in y_coords:
            show_coord(x, y)
  
    pop_matrix()

def show_coord(x, y):
    if x == width:
        x_align = RIGHT
    elif x == 0:
        x_align = LEFT
    else:
        x_align = CENTER
  
    if y == height:
        y_align = BASELINE
    elif y == 0:
        y_align = TOP
    else:
        y_align = CENTER
  
    push_matrix()
    fill(100)
    text_align(x_align, y_align)
    text('(' + str(int(x)) + ', ' + str(int(y)) + ')', x, y)
    pop_matrix()
