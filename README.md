

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