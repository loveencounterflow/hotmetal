


############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'HOTMETAL/MARKDOWN'
#...........................................................................................................
HOTMETAL                  = require '..'
#...........................................................................................................
D                         = require 'pipedreams2'
$                         = D.remit.bind D


#===========================================================================================================
# MARKDOWN
#-----------------------------------------------------------------------------------------------------------
@new_parser = ( settings ) =>
  throw new Error "settings not yet supported" if settings?
  settings =
    html:         true
    linkify:      false
    breaks:       false
    langPrefix:   'codelang-'
    typographer:  true
    quotes:       '“”‘’'
  # MarkdownIt  = require 'markdown-it'
  # return new MarkdownIt settings
  source_references = require 'coffeenode-markdown-it/lib/rules_core/source_references'
  R = ( require 'coffeenode-markdown-it' ) settings
  ### TAINT now is the time to active settings ###
  R = R.use source_references
  # R = R.use source_references, { template: "<rf loc='${start},${stop}'></rf>", }
  # R = R.use source_references, { template: "<!--@(${start},${stop})-->", }
  return R

#-----------------------------------------------------------------------------------------------------------
@as_html = ( md, parser = null ) =>
  return ( parser ? @new_parser() ).render md


#===========================================================================================================
# STREAMING & PIPING
#-----------------------------------------------------------------------------------------------------------
@$as_html = ->
  parser = @new_parser()
  #.........................................................................................................
  return $ ( md, send ) =>
    send @as_html md, parser
