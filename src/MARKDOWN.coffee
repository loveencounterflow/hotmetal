

#===========================================================================================================
# MARKDOWN
#-----------------------------------------------------------------------------------------------------------
@MD = {}

#-----------------------------------------------------------------------------------------------------------
@MD.$as_html = ->
  parser = PIPEDREAMS.HOTMETAL.MD.new_parser()
  #.........................................................................................................
  return $ ( md, send ) =>
    send PIPEDREAMS.HOTMETAL.MD.as_html md, parser


#===========================================================================================================
# MARKDOWN
#-----------------------------------------------------------------------------------------------------------
@MD = {}

#-----------------------------------------------------------------------------------------------------------
@MD.new_parser = ( settings ) =>
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
@MD.as_html = ( md, parser = null ) =>
  return ( parser ? @MD.new_parser() ).render md
