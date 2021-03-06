

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
test                      = require 'guy-test'
H                         = require '..'


#-----------------------------------------------------------------------------------------------------------
handle = ( handler ) ->
  return ( error, result ) ->
    throw error if error?
    handler result


#-----------------------------------------------------------------------------------------------------------
@[ "Dependency availability" ] = ( T, done ) ->
  debug '©OKWgO', H.HTML
  debug '©f65gK', H.HYPHENATOR
  debug '©yEocf', H.LINEBREAKER
  debug '©7YePi', H.MARKDOWN
  debug '©2NQwg', H.TYPO
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Object creation" ] = ( T, done ) ->
  T.eq H._new_hotml(), []
  [ open_tags, test, close_tags, ] = chunk = H._new_chunk()
  T.eq chunk, [ [], '', [], ]
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Object building 1" ] = ( T, done ) ->
  h = H._new_hotml()
  H.add h, 'open-tag', 'div', { class: 'foo bar', }
  H.add h, 'open-tag', 'i', {}
  H.add h, 'text', 'helo '
  H.add h, 'text', 'world!'
  H.add h, 'close-tag', 'i'
  H.add h, 'close-tag', 'div'
  # debug '©hLwNi', JSON.stringify H.as_html h
  T.eq ( H.as_html h ), "<div class=\"foo bar\"><i>helo world!</i></div>"
  T.eq h, [[[["div",{"class":"foo bar"}],["i",{}]],"helo ",[]],[[],"world!",["i","div"]]]
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Object building 2" ] = ( T, done ) ->
  h = H._new_hotml()
  H.add h, 'open-tag', 'div', { class: 'foo bar', }
  H.add h, 'text', 'helo '
  H.add h, 'lone-tag', 'img', { src: 'http:/example.com/y.jpg', class: 'myimg', }
  H.add h, 'open-tag', 'em', {}
  H.add h, 'text', 'beautiful '
  H.add h, 'close-tag', 'em'
  H.add h, 'close-tag', 'div'
  # debug '©hLwNi', JSON.stringify h
  T.eq ( H.as_html h ), "<div class=\"foo bar\">helo <img class=\"myimg\" src=\"http:/example.com/y.jpg\"><em>beautiful</em></div>"
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "is-wrapped 1" ] = ( T, done ) ->
  h = H._new_hotml()
  H.add h, 'open-tag', 'div', { class: 'foo bar', }
  H.add h, 'text', 'helo '
  H.add h, 'lone-tag', 'img', { src: 'http:/example.com/y.jpg', class: 'myimg', }
  H.add h, 'open-tag', 'em', {}
  H.add h, 'text', 'beautiful '
  H.add h, 'close-tag', 'em'
  H.add h, 'close-tag', 'div'
  # debug '©hLwNi', H.rpr h
  # debug '©hLwNi', H.is_wrapped h
  T.eq ( H.is_wrapped h ), true
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "is-wrapped 2" ] = ( T, done ) ->
  h = H._new_hotml()
  H.add h, 'text', 'helo '
  H.add h, 'lone-tag', 'img', { src: 'http:/example.com/y.jpg', class: 'myimg', }
  H.add h, 'open-tag', 'em', {}
  H.add h, 'text', 'beautiful '
  H.add h, 'close-tag', 'em'
  # debug '©hLwNi', H.rpr h
  # debug '©hLwNi', H.is_wrapped h
  T.eq ( H.is_wrapped h ), false
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "unwrapping 1" ] = ( T, done ) ->
  h = H._new_hotml()
  H.add h, 'open-tag', 'div', { class: 'foo bar', }
  H.add h, 'text', 'helo '
  H.add h, 'lone-tag', 'img', { src: 'http:/example.com/y.jpg', class: 'myimg', }
  H.add h, 'open-tag', 'em', {}
  H.add h, 'text', 'beautiful '
  H.add h, 'close-tag', 'em'
  H.add h, 'close-tag', 'div'
  H.unwrap h
  T.eq ( H.as_html h ), """helo <img class="myimg" src="http:/example.com/y.jpg"><em>beautiful</em>"""
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "unwrapping 2" ] = ( T, done ) ->
  h = H._new_hotml()
  H.add h, 'text', 'helo '
  H.add h, 'lone-tag', 'img', { src: 'http:/example.com/y.jpg', class: 'myimg', }
  H.add h, 'open-tag', 'em', {}
  H.add h, 'text', 'beautiful '
  H.add h, 'close-tag', 'em'
  H.unwrap h, yes
  # debug '©hLwNi', H.as_html h
  T.eq ( H.as_html h ), """helo <img class="myimg" src="http:/example.com/y.jpg"><em>beautiful</em>"""
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 1" ] = ( T, done ) ->
  html = """foo bar baz"""
  hotml = H.HTML.parse html
  # T.eq hotml, [ [ [], 'foo ', [] ], [ [], 'bar ', [] ], [ [], 'baz', [] ] ]
  T.eq html, H.as_html hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 2" ] = ( T, done ) ->
  html = """foo <b>bar</b> baz"""
  hotml = H.HTML.parse html
  # debug '©CwlSP', JSON.stringify hotml
  # T.eq hotml, [[[],"foo ",[]],[[["b",{}]],"bar",["b"]],[[]," baz",[]]]
  T.eq html, H.as_html hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 3" ] = ( T, done ) ->
  html = """foo <b>bar awesome</b> baz"""
  hotml = H.HTML.parse html
  # debug '©CwlSP', JSON.stringify hotml
  # T.eq hotml, [[[],"foo ",[]],[[["b",{}]],"bar ",[]],[[],"awe­",[]],[[],"some",["b"]],[[]," baz",[]]]
  T.eq html, H.as_html hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 4" ] = ( T, done ) ->
  html  = """foo <img src="x.jpg"> <b>bar awesome</b> baz"""
  match = [[[],"foo ",[]],[[],"<img src=\"x.jpg\">",[]],[[]," ",[]],[["<b>"],"bar ",[]],[[],"awe­",[]],[[],"some",["</b>"]],[[]," baz",[]]]
  hotml = H.HTML.parse html
  # T.eq hotml, match
  T.eq html, H.as_html hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 5" ] = ( T, done ) ->
  html = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  hotml = H.HTML.parse html
  # help '©i31d2', H.rpr hotml
  # help '©i31d2', JSON.stringify hotml
  # T.eq hotml, [[["<p>"],"foo ",[]],[[],"<img src=\"x.jpg\">",[]],[[]," ",[]],[["<b>"],"bar ",[]],[[],"awe­",[]],[[],"some",["</b>"]],[[]," baz",["</p>"]]]
  T.eq html, H.as_html hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 6" ] = ( T, done ) ->
  html = """<p><i><span class="special">foo</span></i><wrap><img src="x.jpg"></wrap><b>bar awesome</b> baz</p>"""
  hotml = H.HTML.parse html
  # T.eq hotml, [[["<p>","<i>","<span class=\"special\">"],"foo",["</span>","</i>"]],[["<wrap>"],"<img src=\"x.jpg\">",["</wrap>"]],[["<b>"],"bar ",[]],[[],"awe­",[]],[[],"some",["</b>"]],[[]," baz",["</p>"]]]
  T.eq html, H.as_html hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Parsing 7" ] = ( T, done ) ->
  html =   html = """Lo <div id="mydiv"><em><i>arcade &amp; &#x4e00; illustration <img src="x.jpg">
  <b>bromance</b> cyberspace <span class="foo"></span> necessarily</i></em> completely.</div>"""
  hotml = H.HTML.parse html
  # help '©i31d2', H.as_html hotml
  # T.eq hotml, [[[],"Lo ",[]],[["<div id=\"mydiv\">","<em>","<i>"],"ar­",[]],[[],"cade ",[]],[[],"&amp; ",[]],[[],"一 ",[]],[[],"il­",[]],[[],"lus­",[]],[[],"tra­",[]],[[],"tion ",[]],[[],"<img src=\"x.jpg\">",[]],[[]," ",[]],[["<b>"],"bro­",[]],[[],"mance",["</b>"]],[[]," cy­",[]],[[],"ber­",[]],[[],"space ",[]],[["<span class=\"foo\">"],"",["</span>"]],[[]," nec­",[]],[[],"es­",[]],[[],"sar­",[]],[[],"ily",["</i>","</em>"]],[[]," com­",[]],[[],"pletely.",["</div>"]]]
  T.eq ( H.as_html hotml ), 'Lo <div id="mydiv"><em><i>arcade &amp; 一 illustration <img src="x.jpg"> <b>bromance</b> cyberspace <span class="foo"></span> necessarily</i></em> completely.</div>'
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice h`, `H.slice h, 0, h.length` return deep copies of `h`" ] = ( T, done ) ->
  html = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  hotml = H.HTML.parse html
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
  hotml = H.HTML.parse html
  slice = H.slice hotml, -100, Infinity
  T.eq slice, hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice` returns empty list if `start` gte `stop`" ] = ( T, done ) ->
  html = """<p>foo <img src="x.jpg"> <b>bar awesome</b> baz</p>"""
  hotml = H.HTML.parse html
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
  hotml = H.HTML.parse html
  slice = H.slice hotml, 0, 1
  T.eq slice, [[[["p",{}]],"foo ",["p"]]]
  T.eq ( H.as_html slice ), match
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "`H.slice` keeps opening tags from hotml that precedes slice" ] = ( T, done ) ->
  html  = """<p>foo <img src="x.jpg"> <b>bar awesome</b> hotmetal</p>"""
  match = """<p><img src="x.jpg"></p>"""
  hotml = H.HTML.parse html
  # debug '©jLuh7', hotml
  slice = H.slice hotml, 1, 2
  T.eq ( H.as_html slice ), match
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "H.slice honours closing tags" ] = ( T, done ) ->
  html  = """<p><b>very</b> nice <i>and</i> also good <img src="x.jpg"></p>"""
  match = """<p> also good <img src="x.jpg"></p>"""
  hotml = H.HTML.parse html
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
  hotml = H.HTML.parse html
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
  hotml = H.HTML.parse html
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
  hotml = H.HTML.parse html
  T.eq match, H.as_html hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "Special characters 2" ] = ( T, done ) ->
  # foo&bar+baz%64
  html  = """foo <a href="foo&amp;bar+baz%64">baz</a>"""
  match = """foo <a href="foo&amp;bar+baz%64">baz</a>"""
  hotml = H.HTML.parse html
  T.eq match, H.as_html hotml
  done()

#-----------------------------------------------------------------------------------------------------------
@[ "parsing markdown" ] = ( T, done ) ->
  md    = """A *pretty* **sophisticated** story, she said."""
  match = '<p loc="0,1">A <em>pretty</em> <strong>sophisticated</strong> story, she said.</p>\n'
  html  = H.MARKDOWN.as_html md
  T.eq match, html
  done()

# #-----------------------------------------------------------------------------------------------------------
# @[ "hyphenate" ] = ( T, done ) ->
#   html      = '<p loc="0,1">A <em>pretty</em> <strong>sophisticated</strong> story, she said.</p>\n'
#   match     = '<p loc="0,1">A <em>pretty</em> <strong>sophisticated</strong> story, she said.</p>\n'
#   hyphenate = H.HYPHENATOR.new_hyphenate 'hyphenation.en-us', 2
#   debug '©Z4tv2', rpr hyphenate html
#   debug '©Z4tv2', rpr hyphenate 'hyphenation'
#   debug '©8ayz2', H.HTML.parse html
#   # T.eq match, html
#   done()

############################################################################################################
settings = 'timeout': 500
# settings = null
test @, settings
# CND.dir H
