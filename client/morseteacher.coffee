ctx = null
trial = null
observe = 100

# sound

setup = ->
  ctx ||= new ((window?.audioContext or window?.webkitAudioContext))
  osc = ctx.createOscillator()
  osc.type = 'sine'
  osc.frequency.value = 1000
  osc.connect ctx.destination
  osc

timer = (ticks, done=->) ->
  setTimeout done, 60*ticks

beep = (ticks, done=->) ->
  osc = setup()
  osc.start()
  timer ticks, ->
    osc.stop()
    timer 1, done

send = (signal) ->
  tap = (done) ->
    if ticks = signal.shift()
      beep ticks, ->
        tap done
  tap()

signal = (morse) ->
  send morse.split('').map (e) ->
    if e == '.' then 1 else 3

cq = ->
  send [3,1,3,1], ->
  timer 16, ->
    send [3,3,1,3], ->

# alphabet

alphabet = []

parse = (text) ->
  for line in text.split /\n/
    if matches = line.match /(.) ([.-]+) *(\d+)?/
      [all, letter, morse, expect] = matches
      expect = +expect if expect?
      alphabet.push {letter, morse, expect}
  if alphabet.length == 0
    alphabet.push {letter: 'c', morse: '-.-.', expect: 100}
    alphabet.push {letter: 'q', morse: '--.-', expect: 60}

format = ->
  choices = []
  for choice in alphabet
    if choice.expect
      choices.push "#{choice.letter} #{choice.morse} #{Math.round choice.expect}"
    else
      choices.push "#{choice.letter} #{choice.morse}"
  choices.join "\n"

choose = ->
  area = 0
  for choice in alphabet
    area += +(choice.expect || 0)
  area = Math.floor Math.random() * area
  for choice in alphabet
    area -= +(choice.expect || 0)
    return choice if area < 0

bar = (choice) ->
  return '' unless choice.expect
  style = "
    float: left;
    width: 10px;
    height: #{choice.expect}px;
    margin-right: 1px;
    background-color: #bbb;
    text-align:center;
    font-size: 80%;
  "
  "<span style=\"#{style}\">#{choice.letter}</span>"

graph = ($graph) ->
  $graph.empty()
  $graph.append (bar choice for choice in alphabet).join('')

# adapt

advance = ->
  worst = 0
  for choice in alphabet
    if choice.expect
      worst = Math.max worst, +choice.expect
  if worst < 30
    for choice in alphabet
      unless choice.expect
        return choice.expect = 60

resume = ->
  timer 5, ->
    trial = choose()
    signal trial.morse
    observe = 0

score = ->
  old = trial.expect * 0.8
  now = observe * 0.2
  trial.expect = old + now
  advance()
  resume()

# plugin

expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

emit = ($item, item) ->
  alphabet = []
  parse item.text

  prompt = """
    Click here to start.
    Type what you hear.
    Correct answers print.
  """

  $item.append """
    <div style="background-color:#eee;padding:15px;">
      <div class="graph"></div>
      <textarea placeholder="#{prompt}" style="margin-top: 10px;"></textarea>
    </div>
  """

  graph $item.find('.graph')

bind = ($item, item) ->
  $textarea = $item.find('textarea')

  $textarea.focusin ->
    resume()
    
  $textarea.focusout ->
    revision = format()
    unless revision is item.text
      item.text = revision
      $page = $item.parents('.page:first')
      wiki.pageHandler.put $page, {type: 'edit', id: item.id, item: item}

  $textarea.on 'keydown', (e) ->
    if (e.altKey || e.ctlKey || e.metaKey) and e.which == 83 #alt-s
      $textarea.blur()
      e.stopPropagation()
      return false

  $textarea.on 'keyup', (e,val) ->
    response = $textarea.val().slice(-1)
    if response is trial.letter
      score()
    else
      $textarea.val $textarea.val().slice(0,-1)
      observe = 100
    graph $item.find('.graph')

  $item
    .dblclick ->
      wiki.textEditor $item, item


window.plugins.morseteacher = {emit, bind} if window?
module.exports = {expand} if module?

