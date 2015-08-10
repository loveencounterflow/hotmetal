

#===========================================================================================================
# HTML
#-----------------------------------------------------------------------------------------------------------
@HTML = {}

#---------------------------------------------------------------------------------------------------------
@HTML.$parse = ( settings ) ->
  return $ ( html, send ) =>
    send PIPEDREAMS.HOTMETAL.HTML.parse html, settings

#---------------------------------------------------------------------------------------------------------
@HTML.$split = ( settings ) ->
  return $ ( html, send ) =>
    send PIPEDREAMS.HOTMETAL.HTML.split html, settings

#-----------------------------------------------------------------------------------------------------------
@HTML.$slice_toplevel_tags = ->
  return $ ( me, send ) =>
    PIPEDREAMS.HOTMETAL.slice_toplevel_tags me, ( error, slice ) =>
      return send.error error if error?
      send slice

#-----------------------------------------------------------------------------------------------------------
@HTML.$unwrap = ( silent = no) ->
  return $ ( me, send ) =>
    send PIPEDREAMS.HOTMETAL.unwrap me, silent



#===========================================================================================================
# HTML PARSING
#-----------------------------------------------------------------------------------------------------------
@HTML = {}

#-----------------------------------------------------------------------------------------------------------
@HTML._lone_tags = """area base br col command embed hr img input keygen link meta param
    source track wbr""".split /\s+/

#---------------------------------------------------------------------------------------------------------
@HTML.parse = ( html, settings ) =>
  ### TAINT words in code blocks will be hyphenated, too ###
  disperse              = settings?[ 'disperse'     ] ? yes
  hyphenation           = settings?[ 'hyphenation'  ] ? yes
  whitespace            = settings?[ 'whitespace'   ] ? no
  chrs                  = settings?[ 'chrs'         ] ? no
  fragmentize_settings  = { whitespace, chrs, }
  #.........................................................................................................
  if disperse
    fragmentize = @fragmentize.bind @
  #.........................................................................................................
  else
    fragmentize = ( text ) -> [ text, ]
  #.........................................................................................................
  if hyphenation is false
    hyphenate   = ( text ) => text
  else if CND.isa_function hyphenation
    hyphenate   = hyphenation
  else
    hyphenation = if hyphenation is true then null else hyphenation
    hyphenate   = @new_hyphenate hyphenation
  #.........................................................................................................
  handlers =
    #.......................................................................................................
    doctype:  ( name, pid, sid ) => @add R, 'doctype',   name, pid, sid
    endTag:   ( name )           => @add R, 'close-tag', name
    comment:  ( text )           => @add R, 'comment',   CND.escape_html text
    #.......................................................................................................
    text:     ( text ) =>
      text  = CND.escape_html text
      text  = hyphenate text
      for text_part in fragmentize text, fragmentize_settings
        @add R, 'text', text_part
    #.......................................................................................................
    startTag: ( name, a ) =>
      attributes = {}
      ( attributes[ k ] = v for { name: k, value: v, } in a ) if a?
      #.....................................................................................................
      if name in @HTML._lone_tags
        if name is 'wbr'
          throw new Error "illegal <wbr> tag with attributes" if ( Object.keys attributes ).length > 0
          ### as per https://developer.mozilla.org/en/docs/Web/HTML/Element/wbr ###
          @add R, 'text', '\u200b'
        else
          @add R, 'lone-tag', name, attributes
      #.....................................................................................................
      else
        @add R, 'open-tag', name, attributes
  #.........................................................................................................
  parser    = new ( require 'parse5' ).SimpleApiParser handlers
  R         = @_new_hotml()
  parser.parse html
  #.........................................................................................................
  return R

#---------------------------------------------------------------------------------------------------------
@HTML.split = ( html, settings ) =>
  ### A faster parse routine that returns a list whose elements alternatively represent tags and
  texts.

  In the returned list, elements at even indices are always single texts representing openening and closing
  tags, while the elements at odd indices are either single texts (when `disperse` was `false`) or lists
  of texts (when `disperse` was `true`) representing textual contents.  ###
  ### TAINT code duplication ###
  disperse              = settings?[ 'disperse'     ] ? yes
  hyphenation           = settings?[ 'hyphenation'  ] ? yes
  whitespace            = settings?[ 'whitespace'   ] ? no
  chrs                  = settings?[ 'chrs'         ] ? no
  fragmentize_settings  = { whitespace, chrs, }
  last_type             = null
  #.........................................................................................................
  if disperse
    fragmentize = @fragmentize.bind @
  #.........................................................................................................
  else
    fragmentize = ( text ) -> [ text, ]
  #.........................................................................................................
  if hyphenation is false
    hyphenate   = ( text ) => text
  else if CND.isa_function hyphenation
    hyphenate   = hyphenation
  else
    hyphenation = if hyphenation is true then null else hyphenation
    hyphenate   = @new_hyphenate hyphenation
  #.........................................................................................................
  handlers =
    #.......................................................................................................
    doctype:  ( name, pid, sid ) => throw new Error "not implemented" # @add R, 'doctype',   name, pid, sid
    #.......................................................................................................
    comment: ( text ) =>
      # debug '©S9IOL', R
      # debug '©RlDtj', rpr text
      # throw new Error "not implemented" # @add R, 'comment',   CND.escape_html text
      tag = "<!-- #{text} -->"
      if last_type is 'tag'  then R[ R.length - 1 ] += tag
      else                        R.push tag
      #.....................................................................................................
      last_type = 'tag'
    #.......................................................................................................
    endTag: ( name ) =>
      tag = @_render_close_tag name
      #.....................................................................................................
      if last_type is 'tag'  then R[ R.length - 1 ] += tag
      else                        R.push tag
      #.....................................................................................................
      last_type = 'tag'
    #.......................................................................................................
    text:     ( text ) =>
      R.push '' if last_type is null
      text  = CND.escape_html text
      text  = hyphenate text
      if disperse
        text_parts = fragmentize text, fragmentize_settings
        if last_type is 'text' then Array::push.apply R[ R.length - 1 ], text_parts
        else                        R.push text_parts
      else
        if last_type is 'text' then R[ R.length - 1 ] += text
        else                        R.push text
      #.....................................................................................................
      last_type = 'text'
    #.......................................................................................................
    startTag: ( name, attributes ) =>
      tag = @_render_open_tag name, attributes
      #.....................................................................................................
      if last_type is 'tag'  then R[ R.length - 1 ] += tag
      else                        R.push tag
      #.....................................................................................................
      last_type = 'tag'
  #.........................................................................................................
  parser    = new ( require 'parse5' ).SimpleApiParser handlers
  R         = []
  parser.parse html
  #.........................................................................................................
  return R

### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
### # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
###  # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # ###
