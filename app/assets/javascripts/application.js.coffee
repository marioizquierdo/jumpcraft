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


# When the HTML is fully loaded
$ ->

  # Apply twitter bottstrap hooks
  $("a[rel=popover]").popover()
  $(".tooltip").tooltip()
  $("a[rel=tooltip]").tooltip()

  # Draw map canvas
  $('canvas.map-canvas').each (i, el)->
    ctx = el.getContext("2d")
    width = 80
    height = 60
    imgData = ctx.createImageData(width*4, height*4)
    for i in [0..imgData.data.length-1] by 4
      imgData.data[i+0]=255;
      imgData.data[i+1]=0;
      imgData.data[i+2]=0;
      imgData.data[i+3]=255;

    ctx.putImageData(imgData, 0, 0);




