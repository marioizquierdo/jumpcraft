# This is a manifest file that'll be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# the compiled file.
#
# WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
# GO AFTER THE REQUIRES BELOW.
#
#= require jquery
#= require jquery_ujs
#= require twitter/bootstrap
#= require swfobject
#= require_tree .

# Load SWF only if user is signed in
swf_container_id = 'swf-container'
$swf_container = $('#' + swf_container_id)
if $swf_container.length and window.current_user

  swf_url = "https://dl.dropboxusercontent.com/u/8856856/Infiltration.swf"
  flashvars =
    {
      id:         window.current_user._id
      email:      window.current_user.email
      name:       window.current_user.name
      auth_token: window.current_user.authentication_token
      host:       window.location.protocol + '//' + window.location.host
      map_id:     window.flashvars_map_id # null if not in a map view
    }
  console.log 'flashvars', flashvars
  swfobject.embedSWF(swf_url, "swf-container", "640", "480", "10.0.0", false, flashvars)

# Convert hex colors "ff0000" to rgb {r: 255, g: 0, b: 0}
hexToRgb = (hex)->
  if result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    [parseInt(result[1], 16), parseInt(result[2], 16); parseInt(result[3], 16)]
  else
    [0,0,0]

# Given a map canvas, draw the bitmap from the map data
draw_map_on_canvas = (el, mapdatadata)->
  ctx = el.getContext("2d")
  imgData = ctx.createImageData(80, 60)

  dataItems = mapdatadata.split('-')
  bgr_color_hex = (item[6..] for item in dataItems when item[0..5] is 'color_')[0] || 'ffffff'
  bgr_color_rgb = hexToRgb(bgr_color_hex)

  data = dataItems[dataItems.length-1] # data is the last item
  data = data.replace(/_/g, '') # cleanup "_" separators
      
  # Iterate data tiles and paint into the imgData object
  for i in [0...data.length]
    tile = data.charAt(i)
    color = switch tile
      when '0' then bgr_color_rgb # background => color defined in the map data
      when '1', '2', '3'  then [0, 0, 0] # tiles, door and exit => black
      when '4' then [255, 255, 0] # coins => yellow
      when '5' then [255, 0, 0] # spikes => red
      else [0, 0, 0] # anything else => black

    # Draw the color in the imgData array (where every pixel is represented by 4 consecutive elements)
    imgData.data[4*i+0] = color[0] # red
    imgData.data[4*i+1] = color[1] # green
    imgData.data[4*i+2] = color[2] # blue
    imgData.data[4*i+3] = 255      # alpha

  ctx.putImageData(imgData, 0, 0)

# When the HTML is fully loaded
$ ->

  # Apply twitter bottstrap hooks
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()

  # Draw map canvas
  $('canvas.map-canvas').each (i, el)->
    $el = $(el)
    draw_map_on_canvas(el, $el.attr('data-mapdata'))
    $el.on 'click', -> window.location.href = $el.attr('data-href')




