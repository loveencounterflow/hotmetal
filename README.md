

- [HoTMetaL](#hotmetal)
	- [Motivation](#motivation)
	- [The Problem](#the-problem)
	- [The Solution](#the-solution)
		- [Text Partitioning](#text-partitioning)
		- [HTML Partitioning](#html-partitioning)
	- [Why not Just Use TeX?](#why-not-just-use-tex)
	- [API](#api)

> **Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*


# HoTMetaL

![](https://github.com/loveencounterflow/hotmetal/raw/master/art/Linotype_matrices.png)

## Motivation

HoTMetaL has been developed to simplify the finding of good line breaks in HTML sources; this is a core
ingredient for the [MingKwai Typesetter](https://github.com/loveencounterflow/mingkwai-app).

## The Problem

The [MingKwai Typesetter](https://github.com/loveencounterflow/mingkwai-app) is an application to typeset
print pages from MarkDown sources that are converted to HTML5 / CSS3, and then rendered by the browser
component of an [nwjs (formerly node-webkit)](http://nwjs.io/) app.

While the choice of HTML5, CSS3 and a web browser to typeset text is a natural one given that it is the one
globally most widespread text rendering technology, has been under very intense and competitive development
for a quarter of a century now, and has in the process become both highly optimized and internationalized
for a wide range of languages and scripts.

However, producing print masters from a rendering in the browser window has never been very much in the
focus of vendors, and, hence, many of the techniques developed by printers have received a rather negligent
treatment, one example being fine control over how lines are broken into paragraphs, and the typesetting of
columns.

Fortunately, there is a wonderful and versatile programming language—JavaScript—that is closely wedded to
the Document Object Model (DOM) that can be used to fill out any gaps of HTML and CSS.

The particular problem that HoTMetaL is intended to solve can be stated as follows: Given the source of an
HTML paragraph, some collection of CSS style rules and an HTML layout which contains a block element
intended to receive lines of type, how can we make it so that

❶ we can tell whether a given portion of the paragraph fits into the receiving container without
  occupying more than a single line and without containing less material than would be possible, given
  the length of a line?

❷ we can control where line breaks occur to optimize the appearance of a paragraph (as has been pioneered
  by Donal Knuth's TeX typesetting system)?

❸ we can later distribute lines so that common taks in book layout—such as the production of balanced
  columns, possibly with intervening illustrations—become feasible?



## The Solution

The answer to problem ❶ can only be: we must actually typeset a line under 'realistic' conditions, that is,
we must actually put the pertinent HTML tags onto an actual web page and then test whether the line is too
short, just right, or too long. For any attempt to do it 'the TeX way'—i.e. by considering font
metrics instead of actual fonts—is bound to ultimately reconstruct more or less the entire browser rendering
engine in JavaScript, which is certainly too hard to be solved in a satisfactory manner.

The (partial) answer to problem ❷ is that we must find all those positions in a given HTML source text where
line breaks are permitted, given the combination of script and language at a given point. This seemingly
simple task is surprisingly difficult when we consider just a few points:

* In an English text, we require that properly formatted texts use hyphens at the end of lines where
  otherwise a long word would cause an overly short line; those hyphens must only occur where permitted
  by intricate rules (which may not entirely lent themselves to a formalization and may require lists
  of difficult cases and exceptions as dictated by common usage);

* In more traditionally typeset Chinese texts, all the characters, including punctuation, are expected to
  take up the exact same space, so that the result displays a rigid grid. Line breaks may occur at any
  point between any two characters; it may even be permitted to have a trailing period as the first
  (and, at the end of a paragraph, only) character on a line (in more modern Chinese texts, the tendency
  seems to be to abandon the strict grid in favor of variable spacing between characters and give less
  room to punctuation).

* Other languages may use other devices such as elongated characters or, (as in Thai) inner-word breaks
  without hyphens that may, however, only occur at syllable boundaries.

### Text Partitioning

Fortunately, there has been done quite some work in the field of language processing. First, there is the
[Unicode Line Break Algorithm (UAX #14)](http://www.unicode.org/reports/tr14) which has been implemented in
[JavaScript as a NodeJS module called `linebreak`](https://github.com/devongovett/linebreak) and may be
installed as easy as `npm install linebreak`.

Second, there is [a hyphenation module, `hypher`](https://github.com/bramstein/Hypher), with [quite a few
language-specific hyphenation patterns](https://www.npmjs.com/search?q=hyphenation) available.

The combination of `hypher` and `linebreak` allows us to find all positions where e.g. an English text
may be broken. For example, the nonsense text:

```
'Paragraph internationalization assignment (certainly) relativity.'
```

will be partioned as

```
[ 'Para­★', 'graph ', 'in­★', 'ter★­', 'na★­', 'tion★­', 'al­★', 'iza★­', 'tion ',
  'as★­', 'sign★­', 'ment ', '(cer★­', 'tainly) ', 'rel★­', 'a★­', 'tiv★­', 'ity.', ]
```

where the stars `★` indicate 'soft hyphens' (i.e. hyphens that will only be shown when occurring at the end
of the line).

Assuming the existence of method to test whether a given text takes up a single or more than a single line
in the browser, we can, then, take such a partitioning and apply it successively to a web page:

```
➀ ✅ Para-
➅ ✅ Paragraph
➆ ✅ Paragraph in-
➇ ✅ Paragraph inter-
➈ ✅ Paragraph interna-
➉ ✅ Paragraph internation-
➁ ✅ Paragraph international-
➄ ❌ Paragraph internationaliza-
➃ ❌ Paragraph internationalization
➂ ❌ Paragraph internationalization as-
```

A naive method to distribute material accross lines then just tests consecutive lines of increasing lengths;
as soon as it finds the first line that occupies more than a single line, it will accept the 'last good
line' (i.e. the previous line) and re-start the cycle, beginning with the part that caused the line to
become too long (in our case, line ➄ will end up to be typeset, followed by a line that starts with
`Paragraph internationaliza-`). Of course, there may always be unbreakable portions that are too long for a
single line; in such cases, we could typeset that line anyway and issue a quality warning so the user is
alerted and gets a chance to fix things whichever way they see fit.

It's easy to see that the naive method will sometimes produce a fair number of consecutive hyphens,
paragraphs with a lot of hyphenations where a slight adjustment would have yielded less hyphenations, and
paragraphs where spaces happen to occur at similar places in adjacent lines, which produces unsightly
'rivers' of whitespace. But its simplicity and unassuming generality are still attractive; also, it seems to
produce acceptable results in reasonable environments (where the length of words is not too long compared to
the length of the lines). Be it said that it appears to work correctly for English, Chinese, Tibetan, and
Korean; for Thai, a syllable-segmentizer would be needed. This is already quite an achievement given that
it was possible to do with installing a mere two open-source modules from `npm`!

One development left for the future is the adaption of the [TeX (Knuth & Plass) line breaking
algorithm](https://github.com/bramstein/typeset) for the use in HoTMetaL; as it stands, said package uses an
HTML `<canvas>` element to test for line lengths, which is a limitation that has become unnecessary.

Another worthwhile future development may be to implement so-called optical margin alignment, also known as
hanging indentation. Because punctuation (and parts of other characters) are allowed to occupy some space in
the margin, optical alignment does not only achieve a smoother ocerall impression, it also ever so slightly
the effective line lengths, which should contribute to a more balanced spacing.

### HTML Partitioning

It has already been said that in order to correctly test for line lengths, we must produce (partial) lines
under 'realistic' conditions; in other words, it will be necessary to put all of the HTML tags onto the web
page that are in effect for the portion in question. To clarify the problem, let's have a look at another
nonsense snippet of text, this time with peppered wiht meaningless, random tags. In this sample, breakpoints
with soft hyphens are again indicated with `★`, while breakpoints without hyphens are marked ✚.

```
Lo ✚<div id='mydiv'><em><i>✚ar★cade ✚&amp; ✚&#x4e00; ✚il★lus★tra★tion ✚<img src='x.jpg'>
  ✚<b>bro★mance</b>✚ cy★ber★space ✚<span class='foo'></span>✚ nec★es★sar★ily</i></em>✚ com★ple★te★ly.</div>
```


## Why not Just Use TeX?

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