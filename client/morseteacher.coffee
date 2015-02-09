ctx = null
copy = false

setup = ->
  ctx ||= new ((window?.audioContext or window?.webkitAudioContext))
  osc = ctx.createOscillator()
  osc.type = 'sine'
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

cq = ->
  send [3,1,3,1], ->
  timer 16, ->
    send [3,3,1,3], ->

expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'
    .replace /\*(.+?)\*/g, '<i>$1</i>'

emit = ($item, item) ->
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

