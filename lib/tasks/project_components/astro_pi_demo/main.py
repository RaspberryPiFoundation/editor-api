from sense_hat import SenseHat
from time import sleep

sense = SenseHat()
colour = sense.colour
motion = sense.motion

# Sensor output
print("Motion:", motion.motion_detected)
print("Colour:", colour.color)
print("Temperature:", sense.get_temperature())
print("Pressure:", sense.get_pressure())
print("Humidity:",sense.get_humidity())

# # Motion sensor
# def moving_function():
#   print("moving")

# def not_moving_function():
#   print("not moving")

# motion.when_motion = moving_function
# motion.when_no_motion = not_moving_function

# while True:
#   sleep(0.25)

# # Wait for motion function
# motion.wait_for_motion()
# print("it's moving")

# # LED display
# sense.set_rotation(270)
# sense.show_message(":)")
# green = [0,255,0]
# sense.set_pixel(7,7,green)
# sleep(3)
# sense.clear()

# # Testing that changing sensor values can be read mid code run
# while True:
#   print(sense.get_temperature())
#   print(sense.get_pressure())
#   print(sense.get_humidity())
#   print(motion.motion_detected)
#   print(colour.colour)
#   sleep(1)

# # Test that the roll, pitch and yaw are working and update with the 3d model in real time
# while True:
#   print(sense.get_orientation())
#   sleep(1)
