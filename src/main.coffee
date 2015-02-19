

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
    texts
    list_of_close_tags  ] = me
  for text, idx in texts
    R.push t for t in list_of_open_tags[ idx ]
    R.push text
    R.push t for t in list_of_close_tags[ idx ]
  return R.join ''


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

#===========================================================================================================
#
#-----------------------------------------------------------------------------------------------------------
@slice = ( me, start, stop ) ->
  [ i_list_of_open_tags
    i_texts
    i_list_of_close_tags  ] = me
  o_list_of_open_tags       = []
  o_texts                   = []
  o_list_of_close_tags      = []
  R                         = [ o_list_of_open_tags, o_texts, o_list_of_close_tags, ]
  return R if start >= stop
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

#-----------------------------------------------------------------------------------------------------------
@html_structure = ->
  text      = """lo <div id='mydiv'><em><i>arc <b>bo</b> cy <span class='foo'></span> dean</i></em> eps <img src='x.jpg'> foo gig hey</div>"""
  input     = D.create_throughstream()
  #---------------------------------------------------------------------------------------------------------
  input
    .pipe D.HTML.$parse()
    #.......................................................................................................
    .pipe do =>
      open_tags   = []
      texts       = []
      close_tags  = []
      collector   = [ open_tags, texts, close_tags, ]
      last_type   = null
      return $ ( event, send ) =>
        [ type, tail..., ] = event
        #.....................................................................................................
        switch type
          #...................................................................................................
          when 'text', 'lone-tag'
            switch last_type
              #...............................................................................................
              when null, 'close-tag', 'lone-tag', 'text'
                open_tags.push []
                texts.push if type is 'text' then tail[ 0 ] else @render_open_tag tail...
                close_tags.push []
              #...............................................................................................
              when 'open-tag'
                texts[ texts.length - 1 ] = tail[ 0 ]
              #...............................................................................................
              else
                warn "1 ignored event of type #{rpr type}"
          #...................................................................................................
          when 'open-tag'
            switch last_type
              #...............................................................................................
              when null, 'text', 'lone-tag', 'close-tag'
                open_tags.push [ @render_open_tag tail..., ]
                texts.push ''
                close_tags.push []
              #...............................................................................................
              when 'open-tag'
                ( CND.last_of open_tags ).push @render_open_tag tail...
              #...............................................................................................
              else
                warn "2 ignored event of type #{rpr type}"
          #...................................................................................................
          when 'close-tag'
            switch last_type
              #...............................................................................................
              when null
                throw new Error "encountered illegal HTML"
              #...............................................................................................
              when 'text', 'lone-tag', 'close-tag', 'open-tag'
                ( CND.last_of close_tags ).push @render_close_tag tail...
              #...............................................................................................
              else
                warn "3 ignored event of type #{rpr type}"
          #...................................................................................................
          when 'end'
            start = 5
            for stop in [ 5 .. 9 ]
              urge start, stop, @rpr      @slice collector, start, stop
              info start, stop, @as_html  @slice collector, start, stop
            help @rpr     collector
            info @as_html collector
            null
          #...................................................................................................
          else
            warn "4 ignored event of type #{rpr type}"
        #.....................................................................................................
        last_type = type
        send collector
    # #.......................................................................................................
    # .pipe $ ( collector, send ) =>
    #   help @rpr collector
    #   send collector
  #---------------------------------------------------------------------------------------------------------
  input.write text
  input.end()


#===========================================================================================================
# DEMO
#-----------------------------------------------------------------------------------------------------------
@demo = ->
  @html_structure()

############################################################################################################
unless module.parent?
  @demo()





