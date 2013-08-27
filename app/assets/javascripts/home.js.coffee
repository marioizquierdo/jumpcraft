# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

swf_url = "https://dl.dropboxusercontent.com/u/8856856/Infiltration.swf"
flashvars = if window.current_user
  {
    email: window.current_user.email,
    name: window.current_user.name,
    auth_token: window.current_user.authentication_token
  }

swfobject.embedSWF(swf_url, "swf-container", "640", "480", "10.0.0", false, flashvars || {})