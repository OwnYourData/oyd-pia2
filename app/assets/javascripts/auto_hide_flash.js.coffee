$ ->
  flashCallback = ->
    $(".alert:not(.alert-stay)").fadeOut()
  $(".alert:not(.alert-stay)").bind 'click', (ev) =>
    $(".alert:not(.alert-stay)").fadeOut()
  setTimeout flashCallback, 3000
