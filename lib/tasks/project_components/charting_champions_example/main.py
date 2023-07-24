#!/bin/python3
from pygal import Bar

# Create a chart
chart = Bar(title='Olympic medals')

# Add data to the chart
with open('medals.csv') as f:
    data = f.read()
    lines = data.splitlines()
    #print(lines)

    for line in lines:
        tally = line.split(',')
        #print(tally)
        
        team = tally[0]
        medals = tally[1]
        chart.add(team, int(medals))  # Make medals a number

# Display the chart
chart.render()
