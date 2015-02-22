

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr.bind CND
badge                     = 'HOTMETAL/tests'
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
# LODASH                    = require 'lodash'
#...........................................................................................................
# ### https://github.com/dominictarr/event-stream ###
# ES                        = require 'event-stream'
test                      = require 'guy-test'
H                         = require '..'


#-----------------------------------------------------------------------------------------------------------
handle = ( handler ) ->
  return ( error, result ) ->
    throw error if error?
    handler result

# #-----------------------------------------------------------------------------------------------------------
# @[ "Object creation" ] = ( T, done ) ->
#   T.eq H._new_hotml(), []
#   [ open_tags, test, close_tags, ] = chunk = H._new_chunk()
#   T.eq chunk, [ [], '', [], ]
#   # T.ok ( H._open_tags_of  chunk ) is open_tags
#   # T.ok ( H._text_of       chunk ) is test
#   # T.ok ( H._close_tags_of chunk ) is close_tags
#   done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 1" ] = ( T, done ) ->
  html = """foo bar baz"""
  H.parse html, handle ( hotml ) ->
    T.eq hotml, [ [ [], 'foo ', [] ], [ [], 'bar ', [] ], [ [], 'baz', [] ] ]
    T.eq html, H.as_html hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 2" ] = ( T, done ) ->
  html = """foo <b>bar</b> baz"""
  H.parse html, handle ( hotml ) ->
    T.eq hotml, [[[],"foo ",[]],[["<b>"],"bar",["</b>"]],[[]," baz",[]]]
    T.eq html, H.as_html hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 3" ] = ( T, done ) ->
  html = """foo <b>bar awesome</b> baz"""
  H.parse html, handle ( hotml ) ->
    T.eq hotml, [[[],"foo ",[]],[["<b>"],"bar ",[]],[[],"awe­",[]],[[],"some",["</b>"]],[[]," baz",[]]]
    T.eq html, H.as_html hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 4" ] = ( T, done ) ->
  html  = """foo <img src="x.jpg"> <b>bar awesome</b> baz"""
  match = [[[],"foo ",[]],[[],"<img src=\"x.jpg\">",[]],[[]," ",[]],[["<b>"],"bar ",[]],[[],"awe­",[]],[[],"some",["</b>"]],[[]," baz",[]]]
  H.parse html, handle ( hotml ) ->
    T.eq hotml, match
    T.eq html, H.as_html hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 5" ] = ( T, done ) ->
  html = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  H.parse html, handle ( hotml ) ->
    # help '©i31d2', H.rpr hotml
    # help '©i31d2', JSON.stringify hotml
    T.eq hotml, [[["<p>"],"foo ",[]],[[],"<img src=\"x.jpg\">",[]],[[]," ",[]],[["<b>"],"bar ",[]],[[],"awe­",[]],[[],"some",["</b>"]],[[]," baz",["</p>"]]]
    T.eq html, H.as_html hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 6" ] = ( T, done ) ->
  html = """<p><i><span class="special">foo</span></i><wrap><img src="x.jpg"></wrap><b>bar awesome</b> baz</p>"""
  H.parse html, handle ( hotml ) ->
    T.eq hotml, [[["<p>","<i>","<span class=\"special\">"],"foo",["</span>","</i>"]],[["<wrap>"],"<img src=\"x.jpg\">",["</wrap>"]],[["<b>"],"bar ",[]],[[],"awe­",[]],[[],"some",["</b>"]],[[]," baz",["</p>"]]]
    T.eq html, H.as_html hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 7" ] = ( T, done ) ->
  html =   html = """Lo <div id="mydiv"><em><i>arcade &amp; &#x4e00; illustration <img src="x.jpg">
  <b>bromance</b> cyberspace <span class="foo"></span> necessarily</i></em> completely.</div>"""
  H.parse html, handle ( hotml ) ->
    # help '©i31d2', H.as_html hotml
    T.eq hotml, [[[],"Lo ",[]],[["<div id=\"mydiv\">","<em>","<i>"],"ar­",[]],[[],"cade ",[]],[[],"&amp; ",[]],[[],"一 ",[]],[[],"il­",[]],[[],"lus­",[]],[[],"tra­",[]],[[],"tion ",[]],[[],"<img src=\"x.jpg\">",[]],[[]," ",[]],[["<b>"],"bro­",[]],[[],"mance",["</b>"]],[[]," cy­",[]],[[],"ber­",[]],[[],"space ",[]],[["<span class=\"foo\">"],"",["</span>"]],[[]," nec­",[]],[[],"es­",[]],[[],"sar­",[]],[[],"ily",["</i>","</em>"]],[[]," com­",[]],[[],"pletely.",["</div>"]]]
    T.eq ( H.as_html hotml ), 'Lo <div id="mydiv"><em><i>arcade &amp; 一 illustration <img src="x.jpg"> <b>bromance</b> cyberspace <span class="foo"></span> necessarily</i></em> completely.</div>'
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice h`, `H.slice h, 0, h.length` return deep copies of `h`" ] = ( T, done ) ->
  html = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  H.parse html, handle ( hotml ) ->
    T.eq ( slice_0 = H.slice   hotml                     ), hotml
    T.eq ( slice_1 = ( H.slice hotml, 0, hotml.length )  ), hotml
    T.ok slice_0 isnt hotml
    T.ok slice_1 isnt hotml
    T.ok slice_0 isnt slice_1
    T.ok slice_1 isnt hotml
    for [ open_tags_0, _, close_tags_0, ], idx in slice_0
      T.ok open_tags_0  isnt slice_1[ idx ][ 0 ]
      T.ok close_tags_0 isnt slice_1[ idx ][ 2 ]
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice` accepts negative and too big limits" ] = ( T, done ) ->
  html = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  H.parse html, handle ( hotml ) ->
    slice = H.slice hotml, -100, Infinity
    T.eq slice, hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice` returns empty list if `start` gte `stop`" ] = ( T, done ) ->
  html = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  H.parse html, handle ( hotml ) ->
    slice_0 = H.slice hotml, 0, 0
    slice_1 = H.slice hotml, 5, 4
    T.eq slice_0, []
    T.eq slice_1, []
    T.ok slice_0 isnt slice_1
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice` returns list of length 1 if `start + 1` is `stop`" ] = ( T, done ) ->
  html  = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  match = """<p>foo</p>"""
  H.parse html, handle ( hotml ) ->
    slice = H.slice hotml, 0, 1
    T.eq slice, [[["<p>"],"foo ",["</p>"]]]
    T.eq ( H.as_html slice ), match
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice` keeps opening tags from hotml that precedes slice" ] = ( T, done ) ->
  html  = """<p>foo <img src="x.jpg"> <b>bar awesome</b> hotmetal</p>"""
  match = """<p><img src="x.jpg"></p>"""
  H.parse html, handle ( hotml ) ->
    # debug '©jLuh7', hotml
    slice = H.slice hotml, 1, 2
    T.eq ( H.as_html slice ), match
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "H.slice honours closing tags" ] = ( T, done ) ->
  html  = """<p><b>very</b> nice <i>and</i> also good <img src="x.jpg"></p>"""
  match = """<p> also good <img src="x.jpg"></p>"""
  H.parse html, handle ( hotml ) ->
    slice = H.slice hotml, 3, 6
    # debug '©jLuh7', slice
    # debug '©jLuh7', H.as_html slice
    # urge '©jLuh7', H.rpr hotml
    # debug '©jLuh7', H.rpr slice
    # slice = H.slice hotml, 1, 2
    T.eq ( H.as_html slice ), match
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice` 1" ] = ( T, done ) ->
  html    = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  matches = [
    """<p><img src="x.jpg"></p>"""
    """<p><img src="x.jpg"> <b>bar</b></p>"""
    """<p><img src="x.jpg"> <b>bar awe-</b></p>"""
    """<p><img src="x.jpg"> <b>bar awesome</b></p>"""
    """<p><img src="x.jpg"> <b>bar awesome</b> baz</p>"""
    ]
  H.parse html, handle ( hotml ) ->
    start = 1
    idx   = -1
    for stop in [ 3 .. hotml.length ]
      idx    += 1
      match   = matches[ idx ]
      slice   = H.slice hotml, start, stop
      T.eq ( H.as_html slice ), match
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice` 2" ] = ( T, done ) ->
  html    = """a<one>b<two>c<three>d</three>e</two>f</one>g"""
  matches = [
    """a"""
    """a<one>b</one>"""
    """a<one>b<two>c</two></one>"""
    """a<one>b<two>c<three>d</three></two></one>"""
    """a<one>b<two>c<three>d</three>e</two></one>"""
    """a<one>b<two>c<three>d</three>e</two>f</one>"""
    """a<one>b<two>c<three>d</three>e</two>f</one>g"""
    ]
  H.parse html, handle ( hotml ) ->
    start = 0
    idx   = -1
    for stop in [ start + 1 .. hotml.length ]
      idx    += 1
      match   = matches[ idx ]
      slice   = H.slice hotml, start, stop
      T.eq ( H.as_html slice ), match
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Special characters 1" ] = ( T, done ) ->
  html  = """foo <b>foo & < > bar</b> baz"""
  match = """foo <b>foo &amp; &lt; &gt; bar</b> baz"""
  H.parse html, handle ( hotml ) ->
    T.eq match, H.as_html hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Special characters 2" ] = ( T, done ) ->
  # foo&bar+baz%64
  html  = """foo <a href="foo&amp;bar+baz%64">baz</a>"""
  match = """foo <a href="foo&amp;bar+baz%64">baz</a>"""
  H.parse html, handle ( hotml ) ->
    T.eq match, H.as_html hotml
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Line breaking 1" ] = ( T, done ) ->
  #.........................................................................................................
  test_line = ( html ) ->
    # debug '©Dht0s', ( html.length < 10 ), rpr html
    return html.length < 10
  #.........................................................................................................
  set_line = ( html ) ->
    # help html
  #.........................................................................................................
  html  = """Paragraph internationalization assignment (certainly) relativity."""
  match = ["Paragraph","interna-","tional-","ization","assign-","ment","(cer-","tainly)","relativ-","ity."]
  H.break_lines html, test_line, set_line, handle ( lines ) =>
    # urge JSON.stringify lines
    T.eq match, lines
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Line breaking 2" ] = ( T, done ) ->
  count = 0
  #.........................................................................................................
  test_line = ( html ) ->
    count += 1
    return html.length < 30
  #.........................................................................................................
  set_line = ( html ) ->
    # help html
  #.........................................................................................................
  html  = """https://www.google.de/search?q=a+very+long+URL&ie=utf-8&oe=utf-8&gws_rd=cr&ei=4TjpVP3AC8GcPPq1gfgE"""
  match = ["https://​www.google.de/​","search?q=a+very+long","+URL&amp;ie=utf-8&amp;oe=utf-8&amp;gws_rd=cr&amp;ei=4TjpVP3AC8GcP-","Pq1gfgE"]
  H.break_lines html, test_line, set_line, handle ( lines ) =>
    T.eq match, lines
    done()

#-----------------------------------------------------------------------------------------------------------
@[ "Line breaking 3" ] = ( T, done ) ->
  #.........................................................................................................
  test_line = ( html ) ->
    # debug '©Dht0s', ( html.length < 10 ), rpr html
    return html.length < 10
  #.........................................................................................................
  set_line = ( html ) ->
    # help html
  #.........................................................................................................
  html  = """https://www.google.de/search?q=a+very+long+URL&ie=utf-8&oe=utf-8&gws_rd=cr&ei=4TjpVP3AC8GcPPq1gfgE"""
  match = ["https://​","www.google.de/​","search?","q=a+very","+long","+URL&amp;ie=utf-8&amp;oe=utf-8&amp;gws_rd=cr&amp;ei=4TjpVP3AC8GcP-","Pq1gfgE"]
  H.break_lines html, test_line, set_line, handle ( lines ) =>
    # urge JSON.stringify lines
    T.eq match, lines
    done()

############################################################################################################
settings = 'timeout': 500
# settings = null
test @, settings
# CND.dir H
