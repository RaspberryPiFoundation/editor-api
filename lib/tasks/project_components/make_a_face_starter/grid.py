import py5

def grid():
  py5.push_matrix()
  py5.stroke(200)
  py5.fill(0)
  py5.line(0, py5.height/2, py5.width, py5.height/2)
  py5.line(py5.width/2, 0, py5.width/2, py5.height)
  x_coords = [0, py5.width/2, py5.width]
  y_coords = [0, py5.height/2, py5.height]

  for x in x_coords:
    for y in y_coords:
      show_coord(x, y)

  py5.pop_matrix()

def show_coord(x, y):
  if x == py5.width:
    x_align = py5.RIGHT
  elif x == 0:
    x_align = py5.LEFT
  else:
    x_align = py5.CENTER

  if y == py5.height:
    y_align = py5.BASELINE
  elif y == 0:
    y_align = py5.TOP
  else:
    y_align = py5.CENTER

  py5.push_matrix()
  py5.fill(100)
  py5.text_align(x_align, y_align)
  py5.text('(' + str(int(x)) + ', ' + str(int(y)) + ')', x, y)
  py5.pop_matrix()
