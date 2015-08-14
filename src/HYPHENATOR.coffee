

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'HOTMETAL/HYPHENATOR'
#...........................................................................................................
HOTMETAL                  = require '..'
#...........................................................................................................
D                         = require 'pipedreams'
$                         = D.remit.bind D


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
# STREAMING & PIPING
#-----------------------------------------------------------------------------------------------------------
@$hyphenate = ( hyphenation = null, min_length = 4 ) ->
  hyphenate = @new_hyphenate hyphenation, min_length
  return $ ( text, send ) => send hyphenate text, min_length


