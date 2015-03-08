ctx = null
copy = false

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
      alphabet.push {letter, morse, expect}
  if alphabet.length == 0
    alphabet.push {letter: 'c', morse: '-.-.', expect: 100}
    alphabet.push {letter: 'q', morse: '--.-', expect: 60}

choose = ->
  choice = 0
  for trial in alphabet
    choice += +(trial.expect || 0)
  choice = Math.floor Math.random() * choice
  for trial in alphabet
    choice -= +(trial.expect || 0)
    return trial if choice < 0

plot = (trial) ->
  return '' unless trial.expect
  style = "float: left; width: 10px; height: #{trial.expect}px; margin-right: 1px; background-color: #bbb; text-align:center;"
  "<span style=\"#{style}\">#{trial.letter}</span>"

graph = ($graph) ->
  $graph.empty()
  $graph.append (plot trial for trial in alphabet).join('')

# plugin

expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

emit = ($item, item) ->
  alphabet = []
  parse item.text
  trial = choose()
  signal trial?.morse

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
    
  $textarea.on 'keyup', (e,val) ->
    console.log $textarea.val()
    graph $item.find('.graph')


  $item
    .dblclick ->
      wiki.textEditor $item, item


window.plugins.morseteacher = {emit, bind} if window?
module.exports = {expand} if module?

