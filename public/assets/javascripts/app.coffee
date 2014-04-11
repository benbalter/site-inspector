$ ->
  $("#form").submit (e) ->
    e.preventDefault()
    domain = $("#domain").val()
    document.location = "/domains/#{domain}"
    false
