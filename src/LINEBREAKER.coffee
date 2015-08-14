



############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'HOTMETAL/LINEBREAKER'
#...........................................................................................................
HOTMETAL                  = require '..'
# #...........................................................................................................
# D                         = require 'pipedreams'
# $                         = D.remit.bind D



#===========================================================================================================
# UNICODE LINE BREAKING
#-----------------------------------------------------------------------------------------------------------
@fragmentize = ( text, settings ) ->
  text            = text.replace /\n/g, ' '
  last_position   = null
  incremental     = settings?[ 'incremental'  ] ? yes
  chrs            = settings?[ 'chrs'         ] ? no
  extended        = settings?[ 'extended'     ] ? no
  throw new Error "setting `extended` not supported" if extended
  whitespace      = settings?[ 'whitespace'   ] ? no
  matcher         = if whitespace then /(\s+)/ else null
  #.........................................................................................................
  if chrs
    shreds = text.split /// ( (?: [  \ud800-\udbff ] [ \udc00-\udfff ] ) | . ) ///
    R = ( shred for shred in shreds when shred isnt '' )
  #.........................................................................................................
  else
    line_breaker    = new ( require 'linebreak' ) text
    R               = []
    #.......................................................................................................
    while breakpoint = line_breaker.nextBreak()
      { position, required, } = breakpoint
      #.....................................................................................................
      if incremental and last_position? then  part = text[ last_position ... breakpoint.position ]
      else                                    part = text[               ... breakpoint.position ]
      last_position = position
      if whitespace
        R.push subpart for subpart in part.split matcher when subpart.length > 0
      else
        R.push part
  #.......................................................................................................
  return R

# #===========================================================================================================
# # STREAMING & PIPING
# #-----------------------------------------------------------------------------------------------------------
# @$break_lines = ( settings ) ->
#   #.........................................................................................................
#   return $ ( text, send ) =>
#     send @HOTMETAL.break_lines text, settings

