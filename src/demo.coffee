
#===========================================================================================================
# DEMO
#-----------------------------------------------------------------------------------------------------------
@demo = ->
  H = @
  html = """Paragraph internationalization assignment (certainly) relativity."""
  html = """https://github.com/devongovett/linebreak"""
  html = """中國皇帝北京上海香港"""
  html = """볍쌀(영어: rice) 또는 쌀은 벼의 씨앗에서 껍질을 벗겨 낸 식량이다. 그(도정을 한) 정도에 따라, 왕겨만 살짝 벗겨내면 현미(매조미쌀, 핍쌀)가 되고, 곱게 쓿으면 흰쌀(아주먹이)이 된다. 밥이나 떡을 해서 먹으며, 식혜같은 음료나 소주, 청주 등 술의 원료가 된다."""
  html = """ข้าวเป็นธัญพืชซึ่งประชากรโลกบริโภคเป็นอาหารสำคัญ โดยเฉพาะอย่างยิ่งในทวีปเอเชีย จากข้อมูลเมื่อปี"""
  html = """རྩོམ་ཡིག་འདི་ཆ་མི་ཚང་བས་རྩོམ་ཡིག་འདི་ཆ་ཚང་བོར་བཟོས་ནས་ཝེ་ཁེ་རིག་མཛོད་གོང་འཕེལ་གཏོང་རོགས།"""
  html = """Lo <div id='mydiv'><em><i>arcade &amp; &#x4e00; illustration <img src='x.jpg'>
  <b>bromance</b> cyberspace <span class='foo'></span> necessarily</i></em> completely.</div>"""
  H.parse html, ( error, hotml ) =>
    throw error if error?
    for start in [ 0, 3, 10, ]
      for delta in [ 0 .. 15 ]
        stop = start + delta
        # urge start, stop, H.rpr      H.slice hotml, start, stop
        info start, stop, H.as_html  H.slice hotml, start, stop
    urge JSON.stringify hotml
    help H.rpr     hotml
    info H.as_html hotml


############################################################################################################
unless module.parent?
  @demo()

  # debug '©oesB3', CND.last_of ['a', 'b', 'c']
  # debug '©oesB3', CND.first_of ['a', 'b', 'c']


