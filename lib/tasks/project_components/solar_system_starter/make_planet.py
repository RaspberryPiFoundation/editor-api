from p5 import *
import __main__

def make_planet(colour, orbit, size, speed):
    no_stroke()
    fill(colour)
    # 2D transformation
    push_matrix()
    # Centre the orbit on the centre of the model
    translate(width / 2, height / 2)
    # Rotate 'speed' degrees every frame
    rotate(radians((frame_count * speed) % 360)) 
    # Draw the planet
    ellipse(orbit / 2, 0, size, size)
    # End the 2D transformation
    pop_matrix()
