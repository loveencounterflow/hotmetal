

- [HoTMtaL](#hotmtal)
	- [Motivation](#motivation)
	- [The Problem](#the-problem)
	- [The Solution](#the-solution)
	- [API](#api)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


# HoTMtaL

![](https://github.com/loveencounterflow/hotmetal/raw/master/art/Linotype_matrices.png)

## Motivation

HoTMtaL has been developed to simplify the finding of good line breaks in HTML sources; this is a core
ingredient for the [MingKwai Typesetter](https://github.com/loveencounterflow/mingkwai-app).

## The Problem

The [MingKwai Typesetter](https://github.com/loveencounterflow/mingkwai-app) is an application to typeset
print pages from MarkDown sources that are converted to HTML5 / CSS3, and then rendered by the browser
component of an [nwjs (formerly node-webkit)](http://nwjs.io/) app.

While the choice of HTML5, CSS3 and a web browser to typeset text is a natural one given that it is among
the one globally most widespread text rendering technology, has been under very intense and competitive
development for 25 years and has in the process become highly optimized and internationalized for a wide
range of languages and scripts.

However, producing masters intended to be printed to paper from a rendering in the browser window has never
been very much in the focus of browser vendors, and, hence, many of the techniques developed by writers and
printers over the centuries have received a rather negligent treatment, one example being fine control over
how lines are broken into paragraphs, and the typesetting of columns.

Fortunately, we have a wonderful and versatile programming language—JavaScript—that is closely wedded to
the Document Object Model (DOM) that has become the go-to solution to fill out any gaps that HTML and
CSS still have.

<!-- The approach taken  -->




## The Solution

## API

```coffee
H = require 'hotmetal'
html = """<img src='x.jpg'>lo <div id='mydiv'><em><i>arcade &amp; &#x4e00; illustration
<b>bromance</b> cyberspace <span class='foo'></span> necessarily</i></em> completely.</div>"""
H.parse html, ( error, hotml ) =>
  throw error if error?
  for start in [ 0, 3, 10, ]
    for delta in [ 0 .. 5 ]
      stop = start + delta
      # urge start, stop, H.rpr      H.slice hotml, start, stop
      info start, stop, H.as_html  H.slice hotml, start, stop
  urge JSON.stringify hotml
  help H.rpr     hotml
  info H.as_html hotml
```