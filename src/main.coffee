


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
### TAINT should use a (CND?) libary method for these ###
@HTML                     = Object.defineProperty @, 'HTML',        get: -> require './HTML'
@HYPHENATOR               = Object.defineProperty @, 'HYPHENATOR',  get: -> require './HYPHENATOR'
@LINEBREAKER              = Object.defineProperty @, 'LINEBREAKER', get: -> require './LINEBREAKER'
@MARKDOWN                 = Object.defineProperty @, 'MARKDOWN',    get: -> require './MARKDOWN'
@TYPO                     = Object.defineProperty @, 'TYPO',        get: -> require './TYPO'



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
@as_html = ( me, replace_shy = yes ) ->
  R = []
  for chunk, idx in me
    [ open_tags, text, close_tags, ] = chunk
    R.push @_render_open_tag t... for t in open_tags
    R.push @_correct_text me, chunk, idx, replace_shy
    R.push @_render_close_tag t for t in close_tags
  return R.join ''

#-----------------------------------------------------------------------------------------------------------
@_correct_text = ( me, chunk, idx, replace_shy ) ->
  [ open_tags, content, close_tags, ] = chunk
  return @_render_open_tag content... if CND.isa_list content
  is_last = idx is me.length - 1
  #.........................................................................................................
  R = content
  if replace_shy
    R = R.replace /\xad$/,    if is_last then '-' else ''
  R = R.replace /\s+$/, ''  if is_last
  #.........................................................................................................
  return R


#===========================================================================================================
# TAG RENDERING
#-----------------------------------------------------------------------------------------------------------
@_render_open_tag = ( name, attributes ) ->
  ### TAINT inefficient ###
  return ( @_render_empty_tag name, attributes ).replace /<\/[^>]+>$/, ''

#-----------------------------------------------------------------------------------------------------------
@_render_close_tag = ( name ) ->
  return "</#{name}>"

#-----------------------------------------------------------------------------------------------------------
@_render_as_close_tag = ( open_tag ) ->
  ### TAINT inefficient ###
  return @_render_close_tag open_tag.replace /^<([^\s>]+).*$/, '$1'

#-----------------------------------------------------------------------------------------------------------
@_render_empty_tag = ( name, attributes ) ->
  ### TAINT should remove dependency on teacup ###
  TEACUP = require 'coffeenode-teacup'
  return TEACUP.render => TEACUP.TAG name, attributes if attributes?
  return TEACUP.render => TEACUP.TAG name


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
# @copy = ( me ) ->
#   ( [ chunk[ 0 ][ .. ], chunk[ 1 ], chunk[ 2 ][ .. ] ] for chunk in me )


#===========================================================================================================
# TAG MANIPULATION
#-----------------------------------------------------------------------------------------------------------
@TAG = {}

#-----------------------------------------------------------------------------------------------------------
@TAG.add_class = ( tag, clasz ) =>
  ### Add a CSS class. ###
  attributes = tag[ 1 ]
  if ( old_class = attributes[ 'class' ] )?
    return tag if ( old_class.indexOf clasz ) >= 0
    attributes[ 'class' ] += ' ' + clasz
  else
    attributes[ 'class' ] = clasz
  return tag

#-----------------------------------------------------------------------------------------------------------
@TAG.remove_class = ( tag, clasz ) =>
  ### Remove a CSS class. ###
  attributes = tag[ 1 ]
  return tag unless ( old_class = attributes[ 'class' ] )?
  return tag if ( position = old_class.indexOf clasz ) < 0
  if old_class.length is clasz.length
    @TAG.remove tag, 'class'
  else
    attributes[ 'class' ] = ( old_class[ ... position ] + old_class[ position + clasz.length .. ] ).trim()
  return tag

#-----------------------------------------------------------------------------------------------------------
@TAG.get = ( tag, name ) =>
  ### Get an attribute value. ###
  return tag[ 1 ][ name ]

#-----------------------------------------------------------------------------------------------------------
@TAG.set = ( tag, name, value = undefined ) =>
  ### Set an attribute. ###
  tag[ 1 ][ name ] = value
  return tag

#-----------------------------------------------------------------------------------------------------------
@TAG.remove = ( tag, name ) =>
  ### Remove an attribute. ###
  delete tag[ 1 ][ name ]
  return tag

#===========================================================================================================
# SLICING
#-----------------------------------------------------------------------------------------------------------
_copy = ( x ) ->
  # return CND.LODASH.cloneDeep x
  return JSON.parse JSON.stringify x

#-----------------------------------------------------------------------------------------------------------
@slice = ( me, start = 0, stop = null ) ->
  stop             ?= me.length
  start             = Math.max 0, Math.min me.length, start
  stop              = Math.max 0, Math.min me.length, stop
  #.........................................................................................................
  return [] if start >= stop
  R                 = _copy me
  # R                 = CND.LODASH.cloneDeep me
  # R                 = @copy me
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
      first_open_tags.unshift _copy open_tags[ sub_idx ]
      # first_open_tags.unshift CND.LODASH.cloneDeep open_tags[ sub_idx ]
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
    open_tag_count += +open_tags.length
    open_tag_count += -close_tags.length
    #.......................................................................................................
    if open_tag_count is 0
      if open_tags.length > 0 or last_open_tag_count isnt 0
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


