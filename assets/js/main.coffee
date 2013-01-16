home_index_link = (type, tag) ->
  typePart = if type == 'popular' then '' else "/#{type}"
  tagPart = if tag == 'all' then '' else "/tags/#{tag}"

  link = typePart + tagPart

  if link.length == 0
    return '/'

  return link

load_index = (type, tag, push, load) ->
  existingType = $('body').data('type')
  existingTag = $('body').data('tag')

  if existingType == type and existingTag == tag
    return

  if not type?
    type = existingType

  if not tag?
    tag = existingTag
  
  $('body').data 'type', type
  $('body').data 'tag', tag

  $(".selectable.tag-b").removeClass('selected')
  $(".selectable.type-b").removeClass('selected')
  $(".selectable.tag-b[data-val=#{tag}]").addClass('selected')
  $(".selectable.type-b[data-val=#{type}]").addClass('selected')
  
  url = home_index_link(type, tag)
  
  window.history.pushState { type: type, tag: tag }, "", url if push
  return unless load

  $('#modules').addClass('exit')

  replace = null
  run = false

  setTimeout (->
    replace() if replace?
    run = true), 400

  
  $.get url + ".partial", (content) ->
    replace = () ->
      $('#modules').remove()
      $('#main').append(content)
      modules = $('#modules')
      modules.addClass('enter')
      
      # force the style to be recalculated for the transition: 
      # http://stackoverflow.com/questions/3969817/css3-transitions-to-dynamically-created-elements
      window.getComputedStyle(modules.get(0)).getPropertyValue('top')
      modules.removeClass 'enter'

    replace() if run


window.onpopstate = (state) ->
  console.log(state.state)
  if not state.state?
    console.log("Replace")
    window.history.replaceState { type: $('body').data('type'), tag: $('body').data('tag') }, "", window.location
  else
    load_index state.state?.type, state.state?.tag, false, true

$ ->
  $('body').on 'click', 'li[href]', (evt) ->
    window.location = $(this).attr('href')

  $('a.tag').click (evt) ->
    $this = $ this
    tag = $this.text()
    load_index undefined, tag, true, true


    evt.stopPropagation()
    evt.preventDefault()
  
  $('a.type').click (evt) ->
    $this = $ this
    type = $this.text().toLowerCase()
    load_index type, undefined, true, true

    evt.stopPropagation()
    evt.preventDefault()
