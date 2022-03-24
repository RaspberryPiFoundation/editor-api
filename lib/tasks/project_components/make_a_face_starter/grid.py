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
