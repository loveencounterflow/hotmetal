

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'scratch'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
TEACUP                    = require 'coffeenode-teacup'
D                         = require 'pipedreams2'
$                         = D.remit.bind D


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@rpr = ( me ) ->
  return '\n' + CND.columnify me, { paddingChr: '_', }

#-----------------------------------------------------------------------------------------------------------
@as_html = ( me ) ->
  R                       = []
  [ list_of_open_tags
    _
    list_of_close_tags  ] = me
  texts                   = @_get_corrected_texts me
  # debug '©G3WbH', JSON.stringify texts
  for text, idx in texts
    R.push t for t in list_of_open_tags[ idx ]
    R.push text
    R.push t for t in list_of_close_tags[ idx ]
  return R.join ''

#-----------------------------------------------------------------------------------------------------------
@_get_corrected_texts = ( me ) ->
  [ list_of_open_tags
    texts
    list_of_close_tags  ] = me
  R                       = []
  first_idx               = +Infinity
  last_idx                = -Infinity
  #.........................................................................................................
  for text, idx in texts
    if text.length > 0 and text[ 0 ] != '<'
      first_idx = Math.min idx, first_idx
      last_idx  = Math.max idx, last_idx
  # debug '©c9hEz', JSON.stringify texts
  # debug '©vPXZn', first_idx, last_idx
  #.........................................................................................................
  for text, idx in texts
    if text.length > 0 and text[ 0 ] != '<'
      shy_replacement = if idx is last_idx then '-' else ''
      text            = text.replace /\xad$/, shy_replacement
      text            = text.replace /\s+$/, '' if idx is last_idx
      text            = text.replace /&/g, '&amp;'
      text            = text.replace /</g, '&lt;'
      text            = text.replace />/g, '&gt;'
    R.push text
  #.........................................................................................................
  R[ first_idx ] = R[ first_idx ].replace /^\s+/ if R[ first_idx ]?
  return R


#===========================================================================================================
# TAG RENDERING
#-----------------------------------------------------------------------------------------------------------
@render_open_tag = ( name, attributes ) ->
  return ( @render_empty_tag name, attributes ).replace /<\/[^>]+>$/, ''

#-----------------------------------------------------------------------------------------------------------
@render_close_tag = ( name ) ->
  return "</#{name}>"

#-----------------------------------------------------------------------------------------------------------
@render_as_close_tag = ( open_tag ) ->
  return @render_close_tag open_tag.replace /^<([^\s>]+).*$/, '$1'

#-----------------------------------------------------------------------------------------------------------
@render_empty_tag = ( name, attributes ) ->
  return TEACUP.render => TEACUP.TAG name, attributes


# #===========================================================================================================
# # TEXT HYPHENATION
# #-----------------------------------------------------------------------------------------------------------
# @_$hyphenate = ( P... ) ->
#   hyphenate = D.new_hyphenator P...
#   #.........................................................................................................
#   return $ ( event, send ) =>
#     event[ 1 ] = hyphenate event[ 1 ] if event[ 0 ] is 'text'
#     send event


#===========================================================================================================
# POD CREATION
#-----------------------------------------------------------------------------------------------------------
@_new_hotml = -> [ [], [], [], ]

#===========================================================================================================
# SLICING
#-----------------------------------------------------------------------------------------------------------
@slice = ( me, start, stop ) ->
  ### `i` for input ###
  [ i_list_of_open_tags
    i_texts
    i_list_of_close_tags  ] = me
  #.........................................................................................................
  ### `o` for output ###
  [ o_list_of_open_tags
    o_texts
    o_list_of_close_tags  ] = R = @_new_hotml()
  #.........................................................................................................
  return R if start >= stop
  #.........................................................................................................
  start                     = Math.max start, 0
  stop                      = Math.min stop,  i_texts.length - 1
  o_open_tag_count          = 0
  tag_stack                 = []
  initial_open_tags         = []
  initial_close_tags        = []
  o_list_of_open_tags.push initial_open_tags
  o_texts.push ''
  o_list_of_close_tags.push initial_close_tags
  #.........................................................................................................
  ### Walking backwards from `start` to the beginning, collecting closing and opening tags: ###
  for main_idx in [ start - 1 .. 0 ] by -1
    i_open_tags       = i_list_of_open_tags[ main_idx ]
    i_close_tags      = i_list_of_close_tags[ main_idx ]
    o_open_tag_count -= i_close_tags.length
    #.......................................................................................................
    for sub_idx in [ i_open_tags.length - 1 .. 0 ] by -1
      o_open_tag_count += 1
      continue unless o_open_tag_count > 0
      tag_stack.unshift   i_open_tags[ sub_idx ]
      initial_open_tags.unshift i_open_tags[ sub_idx ]
  #.........................................................................................................
  ### Walking forward through the slice: ###
  for main_idx in [ start ... stop ] by +1
    i_open_tags       = i_list_of_open_tags[ main_idx ]
    i_close_tags      = i_list_of_close_tags[ main_idx ]
    o_close_tags      = []
    o_open_tag_count += i_open_tags.length
    o_open_tag_count -= i_close_tags.length
    tag_stack.push i_open_tag for i_open_tag in i_open_tags
    if main_idx is start
      initial_open_tags.push.apply initial_open_tags, i_open_tags
      o_texts[ 0 ] = i_texts[ main_idx ]
      initial_close_tags.push.apply initial_close_tags, i_close_tags
    else
      o_list_of_open_tags.push  CND.LODASH.clone i_open_tags
      o_texts.push              i_texts[ main_idx ]
      o_list_of_close_tags.push CND.LODASH.clone i_close_tags
    tag_stack.pop() for i_close_tag in i_close_tags
  #.........................................................................................................
  ### Closing all remaining open tags: ###
  if tag_stack.length > 0
    target = CND.last_of o_list_of_close_tags
    for idx in [ tag_stack.length - 1 .. 0 ]
      target.push @render_as_close_tag tag_stack[ idx ]
  #.........................................................................................................
  return R


#===========================================================================================================
# PARSING
#-----------------------------------------------------------------------------------------------------------
@parse = ( html, settings, handler ) ->
  switch arity = arguments.length
    when 2
      handler   = settings
      settings  = {}
    when 3
      null
    else throw new Error "expected 2 or 3 arguments, got #{arity}"
  CND.validate_isa_function handler
  @_parse html, settings, handler
  return null

#-----------------------------------------------------------------------------------------------------------
@$parse = ( html ) ->
  throw new Error "not implemented"

#-----------------------------------------------------------------------------------------------------------
@_parse = ( html, settings, handler = null ) ->
  input       = D.create_throughstream()
  _send       = null
  #---------------------------------------------------------------------------------------------------------
  if settings[ 'hyphenation' ] is false
    hyphenate   = ( text ) => text
  else
    hyphenation = if settings[ 'hyphenation' ] is true then null else settings[ 'hyphenation' ]
    hyphenate   = D.new_hyphenator hyphenation
  #---------------------------------------------------------------------------------------------------------
  handler ?= ( error, hotml ) =>
    return _send.error error if error
    _send hotml
  #---------------------------------------------------------------------------------------------------------
  input
    .pipe D.HTML.$parse()
    .pipe D.HTML.$collect_texts()
    #.......................................................................................................
    .pipe do =>
      [ open_tags
        texts
        close_tags ]  = Z = @_new_hotml()
      last_type       = null
      #.....................................................................................................
      return $ ( event, send ) =>
        _send = send
        [ type, tail..., ] = event
        #...................................................................................................
        switch type
          #.................................................................................................
          when 'lone-tag'
            tag = @render_open_tag tail...
            switch last_type
              #.............................................................................................
              when null, 'close-tag', 'lone-tag', 'text'
                open_tags.push []
                texts.push tag
                close_tags.push []
              #.............................................................................................
              when 'open-tag'
                texts[ texts.length - 1 ] = tag
              #.............................................................................................
              else
                return handler new Error "1 ignored event of type #{rpr type}"
          #.................................................................................................
          when 'text'
            text_parts  = D.break_lines hyphenate tail[ 0 ]
            debug '©Kx7Vl', ( rpr tail[ 0 ] ), text_parts
            switch last_type
              #.............................................................................................
              when null, 'close-tag', 'lone-tag', 'text'
                for text_part in text_parts
                  open_tags.push []
                  texts.push text_part
                  close_tags.push []
              #.............................................................................................
              when 'open-tag'
                for text_part, idx in text_parts
                  if idx is 0
                    texts[ texts.length - 1 ] = text_part
                  else
                    open_tags.push []
                    texts.push text_part
                    close_tags.push []
              #.............................................................................................
              else
                return handler new Error "1 ignored event of type #{rpr type}"
          #.................................................................................................
          when 'open-tag'
            switch last_type
              #.............................................................................................
              when null, 'text', 'lone-tag', 'close-tag'
                open_tags.push [ @render_open_tag tail..., ]
                texts.push ''
                close_tags.push []
              #.............................................................................................
              when 'open-tag'
                ( CND.last_of open_tags ).push @render_open_tag tail...
              #.............................................................................................
              else
                return handler new Error "2 ignored event of type #{rpr type}"
          #.................................................................................................
          when 'close-tag'
            switch last_type
              #.............................................................................................
              when null
                throw new Error "encountered illegal HTML"
              #.............................................................................................
              when 'text', 'lone-tag', 'close-tag', 'open-tag'
                ( CND.last_of close_tags ).push @render_close_tag tail...
              #.............................................................................................
              else
                return handler new Error "3 ignored event of type #{rpr type}"
          #.................................................................................................
          when 'end'
            handler null, Z
          #.................................................................................................
          else
            return handler new Error "4 ignored event of type #{rpr type}"
        #...................................................................................................
        last_type = type
        send Z
  #---------------------------------------------------------------------------------------------------------
  input.write html
  input.end()


#===========================================================================================================
# DEMO
#-----------------------------------------------------------------------------------------------------------
@demo = ->
  H = @
  html = """<img src='x.jpg'>lo <div id='mydiv'><em><i>arcade &amp; &#x4e00; illustration
  <b>bromance</b> cyberspace <span class='foo'></span> necessarily</i></em> completely.</div>"""
  html = """Paragraph internationalization assignment (certainly) relativity."""
  H.parse html, ( error, hotml ) =>
    throw error if error?
    for start in [ 0, 3, 10, ]
      for delta in [ 0 .. 15 ]
        stop = start + delta
        # urge start, stop, H.rpr      H.slice hotml, start, stop
        info start, stop, H.as_html  H.slice hotml, start, stop
    urge JSON.stringify hotml
    help H.rpr     hotml
    info H.as_html hotml


############################################################################################################
unless module.parent?
  @demo()

  # debug '©oesB3', CND.last_of ['a', 'b', 'c']
  # debug '©oesB3', CND.first_of ['a', 'b', 'c']



