from p5 import *

circle_radius = 20

col_1 = (255, 0, 0)
pos_1 = (50, 20)

col_2 = (0, 255, 0)
pos_2 = (100, 20)

pos_3 = (150, 20)
col_3 = (0, 0, 255)

pos_4 = (200, 20)
col_4 = (255, 255, 0)

pos_5 = (250, 20)
col_5 = (111,255,0)

my_image = "snake.webp"


def draw():
    add_background(200, 50, 400, 400)
    if is_drawing() and not_in_circle():
        fill(current_color)
        circle(mouse_x, mouse_y, 10)



####### Hide this code #######

# Variable to track drawing state
# Current drawing color
pen_safe = False
current_color = None
default = (0, 0, 0)
image_set = False

def is_drawing():
    return pen_safe
     
    
def get_global_positions():
    # Generate list dynamically
    positions = []
    i = 1
    while f'pos_{i}' in globals():
        positions.append(globals()[f'pos_{i}'])
        i += 1
    return positions


def get_global_colors():
    # Generate list dynamically
    colors = []
    i = 1
    while f'col_{i}' in globals():
        colors.append(globals()[f'col_{i}'])
        i += 1
    return colors


def add_background(x, y, width, height):
    global image_set, background_img
    if not image_set:
        image(background_img, x, y, width, height) 
        image_set = True


def setup():
    global color_choices, current_color, background_img, my_image
    size(800, 800)
    no_stroke()
    background_img = load_image(my_image)
    # Initialize color choices within setup
    color_choices = get_global_colors()
    current_color = Color(default[0],default[1],default[2])  # Default color (black)
    global pen_safe
    color_positions = get_global_positions()
    # Draw color choice circles
    for i, col in enumerate(color_choices):
        draw_circle(color_positions[i], col, circle_radius)
        
def draw_circle(pos, col, radius):
    fill(Color(col[0], col[1], col[2]))
    circle(pos[0], pos[1], radius)


def get_color(col):
    color = Color(col[0], col[1], col[2])
    return color


def check_which_circle():
    global current_color
    color_positions = get_global_positions()
    for i, pos in enumerate(color_positions):
        if dist(mouse_x, mouse_y, *pos) < circle_radius:
            #current_color = Color(color_choices[i][0], color_choices[i][1], color_choices[i][2])
            current_color = get_color(color_choices[i])
            return current_color

def not_in_circle():
    safe = True
    color_positions = get_global_positions()
    for i, pos in enumerate(color_positions):
        if dist(mouse_x, mouse_y, *pos) < circle_radius * 2:
            current_color = color_choices[i]
            safe = False
    return safe

def mouse_pressed():
    global pen_safe
    check_which_circle()
    pen_safe = True  # Start drawing

def mouse_released():
    global pen_safe
    pen_safe = False  # Stop drawing

if __name__ == '__main__':
    run()
