# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

# Load SWF only if user is signed in
if window.current_user
  swf_url = "https://dl.dropboxusercontent.com/u/8856856/Infiltration.swf"
  flashvars =
    {
      id:         window.current_user._id,
      email:      window.current_user.email,
      name:       window.current_user.name,
      auth_token: window.current_user.authentication_token,
      host:       window.location.protocol + '//' + window.location.host
    }
  swfobject.embedSWF(swf_url, "swf-container", "640", "480", "10.0.0", false, flashvars)