

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'HOTMETAL'
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
# D                         = require 'pipedreams2'
# $                         = D.remit.bind D


#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@rpr = ( me ) ->
  R = []
  for chunk, idx in me
    [ open_tags, content, close_tags, ] = chunk
    R.push [ Ro = [], Rt = [], Rc = [] ]
    Ro.push @_render_open_tag t... for t in open_tags
    Rt.push if CND.isa_list content then @_render_open_tag content... else content
    Rc.push @_render_close_tag t for t in close_tags
  return '\n' + CND.columnify R, { paddingChr: '_', }

#-----------------------------------------------------------------------------------------------------------
@as_html = ( me ) ->
  R = []
  for chunk, idx in me
    [ open_tags, text, close_tags, ] = chunk
    R.push @_render_open_tag t... for t in open_tags
    R.push @_correct_text me, chunk, idx
    R.push @_render_close_tag t for t in close_tags
  return R.join ''

#-----------------------------------------------------------------------------------------------------------
@_correct_text = ( me, chunk, idx ) ->
  [ open_tags, content, close_tags, ] = chunk
  return @_render_open_tag content... if CND.isa_list content
  is_last = idx is me.length - 1
  #.........................................................................................................
  R = content
  R = R.replace /\xad$/,    if is_last then '-' else ''
  R = R.replace /\s+$/, ''  if is_last
  #.........................................................................................................
  return R


#===========================================================================================================
# TAG RENDERING
#-----------------------------------------------------------------------------------------------------------
@_render_open_tag = ( name, attributes ) ->
  return ( @_render_empty_tag name, attributes ).replace /<\/[^>]+>$/, ''

#-----------------------------------------------------------------------------------------------------------
@_render_close_tag = ( name ) ->
  return "</#{name}>"

#-----------------------------------------------------------------------------------------------------------
@_render_as_close_tag = ( open_tag ) ->
  return @_render_close_tag open_tag.replace /^<([^\s>]+).*$/, '$1'

#-----------------------------------------------------------------------------------------------------------
@_render_empty_tag = ( name, attributes ) ->
  return TEACUP.render => TEACUP.TAG name, attributes


#===========================================================================================================
# OBJECT CREATION
#-----------------------------------------------------------------------------------------------------------
@_new_hotml     = -> []
@_new_chunk     = -> [ [], '', [], ]


#===========================================================================================================
# OBJECT BUILDING
#-----------------------------------------------------------------------------------------------------------
@add = ( me, type, tail... ) ->
  ### TAINT ??? won't work correctly with empty tags because we check for `text.length == 0` ??? ###
  me.push @_new_chunk() if me.length is 0
  target  = CND.last_of me
  #.........................................................................................................
  switch type
    when 'open-tag', 'lone-tag', 'text'
      if target[ 1 ].length > 0 or target[ 2 ].length > 0
        me.push target = @_new_chunk()
    else
      null
  #.........................................................................................................
  switch type
    #.......................................................................................................
    when 'open-tag'
      target[ 0 ].push tail
      # target[ 0 ].push @_render_open_tag tail...
    #.......................................................................................................
    when 'lone-tag'
      target[ 1 ] = tail
      # target[ 1 ] = @_render_open_tag tail...
    #.......................................................................................................
    when 'lone-tag', 'text'
      target[ 1 ] = tail[ 0 ]
    #.......................................................................................................
    when 'close-tag'
      target[ 2 ].push tail[ 0 ]
      # target[ 2 ].push @_render_close_tag tail[ 0 ]
    #.......................................................................................................
    when 'comment', 'doctype'
      null
    #.......................................................................................................
    else
      throw new Error "unknown type #{rpr type}"
  #.........................................................................................................
  return me

#-----------------------------------------------------------------------------------------------------------
@copy = ( me ) ->
  ( [ chunk[ 0 ][ .. ], chunk[ 1 ], chunk[ 2 ][ .. ] ] for chunk in me )


#===========================================================================================================
# SLICING
#-----------------------------------------------------------------------------------------------------------
@slice = ( me, start = 0, stop = null ) ->
  stop             ?= me.length
  start             = Math.max 0, Math.min me.length, start
  stop              = Math.max 0, Math.min me.length, stop
  #.........................................................................................................
  return [] if start >= stop
  # R                 = CND.LODASH.cloneDeep me
  R                 = @copy me
  return R if start is 0 and stop is me.length
  #.........................................................................................................
  R                 = R.slice start, stop
  open_tag_count    = 0
  first_open_tags   = R[ 0            ][ 0 ]
  last_close_tags   = R[ R.length - 1 ][ 2 ]
  tag_stack         = []
  #.........................................................................................................
  ### Walking backwards from `start` to the beginning, collecting closing and opening tags: ###
  for main_idx in [ start - 1 .. 0 ] by -1
    [ open_tags, text, close_tags, ]  = me[ main_idx ]
    open_tag_count                 -= close_tags.length
    #.......................................................................................................
    for sub_idx in [ open_tags.length - 1 .. 0 ] by -1
      open_tag_count += 1
      continue unless open_tag_count > 0
      first_open_tags.unshift open_tags[ sub_idx ]
  #.........................................................................................................
  ### Closing all remaining open tags: ###
  for [ open_tags, text, close_tags, ] in R
    tag_stack.push open_tag[ 0 ] for open_tag in open_tags
    tag_stack.pop() for close_tag in close_tags
  # debug '©9Gwy3', tag_stack
  for idx in [ tag_stack.length - 1 .. 0 ] by -1
    last_close_tags.push tag_stack[ idx ]
    # last_close_tags.push @_render_as_close_tag tag_stack[ idx ]
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@slice_toplevel_tags = ( me, handler = null ) ->
  ### TAINT make ignorable inter-tag WS configurable? ###
  open_tag_count        = 0
  last_open_tag_count   = 0
  start                 = null
  stop                  = null
  R                     = if handler? then null else []
  #.........................................................................................................
  for chunk, chunk_idx in me
    [ open_tags, text, close_tags, ] = chunk
    #.......................................................................................................
    if open_tag_count is 0
      if open_tags.length is 0
        unless /^\s*$/.test text
          error = new Error "invalid HoTMetaL structure: detected printing material between toplevel tags"
          if handler? then return handler error else throw error
      else
        start = chunk_idx
    #.......................................................................................................
    open_tag_count += open_tags.length
    open_tag_count -= close_tags.length
    #.......................................................................................................
    if open_tag_count is 0
      if last_open_tag_count isnt 0
        stop  = chunk_idx + 1
        slice = @slice me, start, stop
        if handler? then handler null, slice else R.push slice
    else if open_tag_count < 0
      error = new Error "invalid HoTMetaL structure"
      if handler? then return handler error else throw error
    #.......................................................................................................
    last_open_tag_count = open_tag_count
  #.........................................................................................................
  return R

#-----------------------------------------------------------------------------------------------------------
@is_wrapped = ( me ) ->
  tag_stack       = []
  last_chunk_idx  = me.length - 1
  ### TAINT use library method ###
  # name_from_tag   = ( tag ) -> tag.replace /^<\/?([^\s>]+).*$/, '$1'
  #.........................................................................................................
  for [ open_tags, text, close_tags, ], chunk_idx in me
    return false if chunk_idx is 0 and open_tags.length is 0
    is_last_chunk                     = chunk_idx is last_chunk_idx
    last_tag_idx                      = close_tags.length - 1
    ( tag_stack.push open_tag[ 0 ] ) for open_tag in open_tags
    #.......................................................................................................
    for close_tag_name, tag_idx in close_tags
      is_last_tag     = is_last_chunk and tag_idx is last_tag_idx
      open_tag_name   = tag_stack.pop()
      unless open_tag_name is close_tag_name
        throw new Error "unbalanced tags: #{rpr open_tag_name} isnt #{rpr close_tag_name}"
      return is_last_tag if tag_stack.length is 0
  #.........................................................................................................
  return false

#-----------------------------------------------------------------------------------------------------------
@unwrap = ( me, silent = no ) ->
  if @is_wrapped me
    ( CND.first_of me )[ 0 ].shift()
    ( CND.last_of  me )[ 2 ].pop()
  else unless silent
    throw new Error "HTML does not form a wrapped structure"
  return me

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

#===========================================================================================================
# LINE BREAKING
#-----------------------------------------------------------------------------------------------------------
@break_lines = ( me, test_line, set_line ) ->
  start             = 0
  stop              = start
  last_slice        = null
  slice             = null
  is_first_line     = yes
  is_last_line      = no
  is_first_try      = yes
  #.......................................................................................................
  loop
    stop        += 1
    is_last_line = ( stop > me.length ) or ( stop - start is 0 and stop == me.length )
    #.....................................................................................................
    if is_last_line
      if last_slice?
        set_line last_slice, is_first_line, is_last_line if set_line?
      else if slice?
        set_line slice, is_first_line, is_last_line if set_line?
      return null
    #.....................................................................................................
    slice = @slice me, start, stop
    fits  = test_line slice, is_first_line, is_last_line
    #.....................................................................................................
    if fits
      last_slice        = slice
    else
      #...................................................................................................
      if last_slice?
        set_line last_slice, is_first_line, is_last_line if set_line?
        last_slice  = null
        start       = stop - 1
        stop        = start
      #...................................................................................................
      else
        set_line slice, is_first_line, is_last_line if set_line?
        slice = null
        start = stop
        stop  = start
      #...................................................................................................
      is_first_line = no
  #.......................................................................................................
  throw new Error "should never happen"


#===========================================================================================================
# UNICODE LINE BREAKING
#-----------------------------------------------------------------------------------------------------------
@fragmentize = ( text, settings ) ->
  text            = text.replace /\n/g, ' '
  last_position   = null
  incremental     = settings?[ 'incremental'  ] ? yes
  extended        = settings?[ 'extended'     ] ? no
  #.........................................................................................................
  line_breaker    = new ( require 'linebreak' ) text
  R               = []
  #.......................................................................................................
  while breakpoint = line_breaker.nextBreak()
    { position, required, } = breakpoint
    #.....................................................................................................
    if incremental and last_position? then  part = text[ last_position ... breakpoint.position ]
    else                                    part = text[               ... breakpoint.position ]
    last_position = position
    R.push if extended then [ part, required, position, ] else part
  #.......................................................................................................
  return R


#===========================================================================================================
# HYPHENATION
#-----------------------------------------------------------------------------------------------------------
@new_hyphenate = ( hyphenation = null, min_length = 2 ) ->
  ### https://github.com/bramstein/hypher ###
  Hypher        = require 'hypher'
  hyphenation  ?= require 'hyphenation.en-us'
  HYPHER        = new Hypher hyphenation
  return HYPHER.hyphenateText.bind HYPHER


#===========================================================================================================
# TYPOGRAPHIC ENHANCEMENTS
#-----------------------------------------------------------------------------------------------------------
@TYPO = {}
@TYPO.quotes = ( text ) => ( require 'typogr' ).smartypants text
@TYPO.dashes = ( text ) => ( require 'typogr' ).smartypants text


#===========================================================================================================
# MARKDOWN
#-----------------------------------------------------------------------------------------------------------
@MD = {}

#-----------------------------------------------------------------------------------------------------------
@MD.new_parser = ( settings ) =>
  throw new Error "settings not yet supported" if settings?
  settings =
    html: true,
    linkify: true,
    typographer: true
  MarkdownIt  = require 'markdown-it'
  return new MarkdownIt settings

#-----------------------------------------------------------------------------------------------------------
@MD.as_html = ( md, parser = null ) =>
  return ( parser ? @new_parser() ).render md



#===========================================================================================================
# HTML PARSING
#-----------------------------------------------------------------------------------------------------------
@HTML = {}

#---------------------------------------------------------------------------------------------------------
@HTML.parse = ( html, disperse = yes, hyphenation = yes ) =>
  lone_tags = """area base br col command embed hr img input keygen link meta param
    source track wbr""".split /\s+/
  #.........................................................................................................
  if disperse
    fragmentize = @fragmentize.bind @
    if hyphenation is false
      hyphenate   = ( text ) => text
    else if CND.isa_function hyphenation
      hyphenate   = hyphenation
    else
      hyphenation = if hyphenation is true then null else hyphenation
      hyphenate   = @new_hyphenate hyphenation
  #.........................................................................................................
  else
    fragmentize = ( text ) -> [ text, ]
    hyphenate   = ( text ) => text
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
      for text_part in fragmentize text
        @add R, 'text', text_part
    #.......................................................................................................
    startTag: ( name, a ) =>
      attributes = {}
      ( attributes[ k ] = v for { name: k, value: v, } in a ) if a?
      #.....................................................................................................
      if name in lone_tags
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

#===========================================================================================================
# BALANCED COLUMNS
#-----------------------------------------------------------------------------------------------------------
@get_column_linecounts = ( strategy, line_count, column_count ) ->
  ### thx to http://stackoverflow.com/a/1244369/256361 ###
  R   = []
  #.........................................................................................................
  switch strategy
    #.......................................................................................................
    when 'even'
      for col in [ 1 .. column_count ]
        R.push ( line_count + column_count - col ) // column_count
    #.......................................................................................................
    else
      throw new Error "unknown strategy #{rpr strategy}"
  #.........................................................................................................
  return R


#===========================================================================================================
# DEMO
#-----------------------------------------------------------------------------------------------------------
@demo = ->
  H = @
  html = """Paragraph internationalization assignment (certainly) relativity."""
  html = """https://github.com/devongovett/linebreak"""
  html = """中國皇帝北京上海香港"""
  html = """볍쌀(영어: rice) 또는 쌀은 벼의 씨앗에서 껍질을 벗겨 낸 식량이다. 그(도정을 한) 정도에 따라, 왕겨만 살짝 벗겨내면 현미(매조미쌀, 핍쌀)가 되고, 곱게 쓿으면 흰쌀(아주먹이)이 된다. 밥이나 떡을 해서 먹으며, 식혜같은 음료나 소주, 청주 등 술의 원료가 된다."""
  html = """ข้าวเป็นธัญพืชซึ่งประชากรโลกบริโภคเป็นอาหารสำคัญ โดยเฉพาะอย่างยิ่งในทวีปเอเชีย จากข้อมูลเมื่อปี"""
  html = """རྩོམ་ཡིག་འདི་ཆ་མི་ཚང་བས་རྩོམ་ཡིག་འདི་ཆ་ཚང་བོར་བཟོས་ནས་ཝེ་ཁེ་རིག་མཛོད་གོང་འཕེལ་གཏོང་རོགས།"""
  html = """Lo <div id='mydiv'><em><i>arcade &amp; &#x4e00; illustration <img src='x.jpg'>
  <b>bromance</b> cyberspace <span class='foo'></span> necessarily</i></em> completely.</div>"""
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



