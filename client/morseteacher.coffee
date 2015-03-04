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
    [all, letter, morse, expect] = line.match /(.) ([.-]+) *(\d+)?/
    alphabet.push {letter, morse, expect}

choose = ->
  choose = 0
  for trial in alphabet
    choose += +(trial.expect || 0)
  choose = Math.floor Math.random() * choose
  for trial in alphabet
    choose -= +(trial.expect || 0)
    return trial if choose < 0

# plugin

expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

emit = ($item, item) ->
  parse item.text
  signal choose().morse

  $item.append """
    <p style="background-color:#eee;padding:15px;">
      #{expand item.text}
      <button>copy</button>
    </p>
  """

bind = ($item, item) ->
  $button = $item.find('button')
  $button.on 'click', ->
    label = if (copy = !copy)
      cq()
      'stop'
    else
      'copy'
    $button.text label
  $item.dblclick ->
    wiki.textEditor $item, item

window.plugins.morseteacher = {emit, bind} if window?
module.exports = {expand} if module?

