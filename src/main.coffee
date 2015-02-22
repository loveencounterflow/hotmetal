

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
D                         = require 'pipedreams2'
$                         = D.remit.bind D

#===========================================================================================================
# HELPERS
#-----------------------------------------------------------------------------------------------------------
@rpr = ( me ) ->
  return '\n' + CND.columnify me, { paddingChr: '_', }

#-----------------------------------------------------------------------------------------------------------
@as_html = ( me ) ->
  R = []
  for chunk, idx in me
    [ open_tags, text, close_tags, ] = chunk
    R.push t for t in open_tags
    R.push @_correct_text me, chunk, idx
    R.push t for t in close_tags
  return R.join ''

#-----------------------------------------------------------------------------------------------------------
@_correct_text = ( me, chunk, idx ) ->
  [ open_tags, text, close_tags, ] = chunk
  return text if text.length > 0 and text[ 0 ] is '<'
  is_last = idx is me.length - 1
  #.........................................................................................................
  R = text
  R = R.replace /\xad$/,    if is_last then '-' else ''
  R = R.replace /\s+$/, ''  if is_last
  ### TAINT must escape HTML special chrs ###
  # R               = R.replace /&/g, '&amp;'
  # R               = R.replace /</g, '&lt;'
  # R               = R.replace />/g, '&gt;'
  #.........................................................................................................
  # R[ first_idx ] = R[ first_idx ].replace /^\s+/ if R[ first_idx ]?
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
# POD CREATION
#-----------------------------------------------------------------------------------------------------------
@_new_hotml     = -> []
@_new_chunk     = -> [ [], '', [], ]


#===========================================================================================================
# SLICING
#-----------------------------------------------------------------------------------------------------------
@slice = ( me, start = 0, stop = null ) ->
  stop              ?= me.length
  start              = Math.max start, 0
  stop               = Math.min stop,  me.length
  #.........................................................................................................
  return [] if start >= stop
  R                 = CND.LODASH.cloneDeep me
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
    tag_stack.push open_tag for open_tag in open_tags
    tag_stack.pop() for close_tag in close_tags
  # debug '©9Gwy3', tag_stack
  for idx in [ tag_stack.length - 1 .. 0 ] by -1
    last_close_tags.push @_render_as_close_tag tag_stack[ idx ]
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
@$parse = ->
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
    hyphenate   = D.new_hyphenate hyphenation
  #---------------------------------------------------------------------------------------------------------
  handler ?= ( error, hotml ) =>
    return _send.error error if error
    _send hotml
  #---------------------------------------------------------------------------------------------------------
  input
    .pipe D.HTML.$parse()
    .pipe D.HTML.$collect_texts()
    .pipe D.HTML.$disperse_texts settings[ 'hyphenation' ] ? null
    # .pipe D.$show()
    #.......................................................................................................
    .pipe do =>
      Z         = @_new_hotml()
      last_type = null
      #.....................................................................................................
      return $ ( event, send ) =>
        _send = send
        [ type, tail..., ] = event
        #...................................................................................................
        switch type
          #.................................................................................................
          when 'text', 'lone-tag'
            if type is 'text' then  text = tail[ 0 ]
            else                    text = @_render_open_tag tail...
            # debug '©Kx7Vl', ( rpr tail[ 0 ] ), text_parts
            switch last_type
              #.............................................................................................
              when null, 'close-tag', 'lone-tag', 'text'
                Z.push chunk  = @_new_chunk()
                chunk[ 1 ]    = text
              #.............................................................................................
              when 'open-tag'
                ( CND.last_of Z )[ 1 ] = text
              #.............................................................................................
              else
                return handler new Error "1 ignored event of type #{rpr type}"
          #.................................................................................................
          when 'open-tag'
            switch last_type
              #.............................................................................................
              when 'text', null, 'lone-tag', 'close-tag'
                Z.push [ open_tags, ... ] = @_new_chunk()
                open_tags.push @_render_open_tag tail...
              #.............................................................................................
              when 'open-tag'
                ( CND.last_of Z )[ 0 ].push @_render_open_tag tail...
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
                ( CND.last_of Z )[ 2 ].push @_render_close_tag tail...
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
# LINE BREAKING
#-----------------------------------------------------------------------------------------------------------
@break_lines = ( html, test_line, set_line, handler ) ->
  switch arity = arguments.length
    when 3
      handler   = set_line
      set_line  = null
    when 4
      null
    else
      throw new Error "expected 3 or 4 arguments, got #{arity}"
  #---------------------------------------------------------------------------------------------------------
  @.parse html, ( error, hotml ) =>
    return handler error if error?
    start             = 0
    stop              = start
    last_slice        = null
    last_slice_hotml  = null
    lines             = []
    slice             = null
    is_first_line     = yes
    is_last_line      = no
    is_first_try      = yes
    #.......................................................................................................
    loop
      stop   += 1
      is_last_line = ( stop > hotml.length ) or ( stop - start is 0 and stop == hotml.length )
      #.....................................................................................................
      if is_last_line
        if last_slice?
          set_line last_slice, is_first_line, is_last_line, last_slice_hotml if set_line?
          lines.push last_slice
        else if slice?
          set_line slice, is_first_line, is_last_line, slice_hotml if set_line?
          lines.push slice
        return handler null, lines
      #.....................................................................................................
      slice_hotml = @slice hotml, start, stop
      slice       = @as_html slice_hotml
      fits        = test_line slice, is_first_line, is_last_line, slice_hotml
      #.....................................................................................................
      if fits
        last_slice        = slice
        last_slice_hotml  = slice_hotml
      else
        #...................................................................................................
        if last_slice?
          set_line last_slice, is_first_line, is_last_line, last_slice_hotml if set_line?
          lines.push last_slice
          last_slice  = null
          start       = stop - 1
          stop        = start
        #...................................................................................................
        else
          set_line slice, is_first_line, is_last_line, slice_hotml if set_line?
          lines.push slice
          slice = null
          start = stop
          stop  = start
        #...................................................................................................
        is_first_line = no

#-----------------------------------------------------------------------------------------------------------
@$break_lines = ( test_line ) ->
  return $ ( html, send ) =>
    @break_lines html, test_line, null, ( error, lines ) =>
      send lines


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



