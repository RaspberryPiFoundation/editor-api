# Definitions for compatibility with the p5py processing library 
from processing import *
import __main__

# Shape
from processing import rectMode as rect_mode
from processing import ellipseMode as ellipse_mode
from processing import strokeWeight as stroke_weight
from processing import strokeCap as stroke_cap
from processing import strokeJoin as stroke_join
from processing import noStroke as no_stroke
from processing import noFill as no_fill

# Fonts
from processing import createFont as create_font
from processing import loadFont as load_font
from processing import textFont as text_font

# Text
from processing import textAlign as text_align
from processing import textLeading as text_leading
from processing import textMode as text_mode
from processing import textSize as text_size
from processing import textWidth as text_width

# Colour
from processing import blendColor as blend_color
from processing import lerpColor as lerp_color
from processing import color as Color
  
# Images
from processing import createImage as create_image
from processing import imageMode as image_mode
from processing import loadImage as load_image
from processing import noTint as no_tint
from processing import requestImage as request_image

# Environment
from processing import frameRate as frame_rate
from processing import noCursor as no_cursor
from processing import noLoop as no_loop

# Transform
from processing import applyMatrix as apply_matrix
from processing import popMatrix as pop_matrix
from processing import printMatrix as print_matrix
from processing import pushMatrix as push_matrix
from processing import resetMatrix as reset_matrix
from processing import rotateX as rotate_x
from processing import rotateY as rotate_y
from processing import pushStyle as push_style
from processing import popStyle as pop_style

from processing import run as main_run

# Keyboard

def mousePressed():
  if hasattr(__main__, "mouse_pressed"):
    mouse_pressed = getattr(__main__, "mouse_pressed")
    mouse_pressed()
    
def mouseReleased():
  if hasattr(__main__, "mouse_released"):
    mouse_released = getattr(__main__, "mouse_released")
    mouse_released()
  
__main__.mouse_x = 0
__main__.mouse_y = 0
__main__.mouse_px = 0
__main__.mouse_py = 0
__main__.frame_count = 0
__main__.frame_rate = 60

def mouseMoved():
  __main__.mouse_x = mouse.x
  __main__.mouse_y = mouse.y
  __main__.mouse_px = mouse.px
  __main__.mouse_py = mouse.py
  if hasattr(__main__, "mouse_moved"):
    mouse_moved = getattr(__main__, "mouse_moved")
    mouse_moved()

def mouseDragged():
  if hasattr(__main__, "mouse_dragged"):
    mouse_dragged = getattr(__main__, "mouse_dragged")
    mouse_dragged()

def new_draw():
  __main__.frame_count = frameCount
  frameRate = __main__.frame_rate
  old_draw()
  
def run():
  global old_draw
  old_draw = __main__.draw
  __main__.draw = new_draw
  main_run()
  
def grid():
  pushMatrix()
  stroke(200)
  fill(0)
  line(0, height/2, width, height/2)
  line(width/2, 0, width/2, height)
  x_coords = [0, width/2, width]
  y_coords = [0, height/2, height]
 
  for x in x_coords:
    for y in y_coords:
      show_coord(x, y)

  popMatrix()

def circle(x, y, w):
  ellipse(x, y, w, w)
  
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
    
  pushStyle()
  fill(100)
  text_align(x_align, y_align)
  text('(' + str(int(x)) + ', ' + str(int(y)) + ')', x, y)
  popStyle()
  
