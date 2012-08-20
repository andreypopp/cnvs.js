'use strict'

(() ->

  window.cnvs = cnvs = {}

  pfx = (() ->
    style = document.createElement('dummy').style
    prefixes = 'Webkit Moz O ms Khtml'.split(' ')
    memory = {}

    (prop) ->
      if typeof memory[prop] == "undefined"
        ucProp = prop.charAt(0).toUpperCase() + prop.substr(1)
        props = (prop + ' ' + prefixes.join(ucProp + ' ') + ucProp).split(' ')

        memory[prop] = null
        for i in props
          if style[props[i]] != undefined
            memory[prop] = props[i]
            break

      memory[prop]
  )()

  css = (el, props) ->
    for key in props
      if props.hasOwnProperty(key)
        pkey = pfx(key)
        if pkey != null
          el.style[pkey] = props[key]
    el

  # `translate` builds a translate transform string for given data.
  translate = (t) ->
    " translate3d(#{t.x}px,#{t.y}px,#{t.z}px) "

  # `rotate` builds a rotate transform string for given data.
  # By default the rotations are in X Y Z order that can be reverted by passing `true`
  # as second parameter.
  rotate = (r, revert) ->
    rX = " rotateX(" + r.x + "deg) "
    rY = " rotateY(" + r.y + "deg) "
    rZ = " rotateZ(" + r.z + "deg) "
    revert ? rZ+rY+rX : rX+rY+rZ

  # `scale` builds a scale transform string for given data.
  scale = (s) ->
    " scale(#{s}) "

  # `perspective` builds a perspective transform string for given data.
  perspective = (p) ->
    " perspective(#{p}px) "

  class Cnvs

    constructor: (options) ->
      this.options = options
      this.root = $(options.root)
      this.canvas = $('<div></div>').appendTo(this.canvas)
      this.currentState =
        translate: {x: 0, y: 0, z: 0}
        rotate: {x: 0, y: 0, z: 0}
        scale: 1

    gotoStep: (step, duration) ->

      # Sometimes it's possible to trigger focus on first link with some keyboard action.
      # Browser in such a case tries to scroll the page to make this element visible
      # (even that body overflow is set to hidden) and it breaks our careful positioning.
      #
      # So, as a lousy (and lazy) workaround we will make the page scroll back to the top
      # whenever slide is selected
      #
      # If you are reading this and know any better way to handle it, I'll be glad to hear about it!
      window.scrollTo(0, 0)

      # compute target state of the canvas based on given step
      target =
        rotate:
          x: -step.rotate.x
          y: -step.rotate.y
          z: -step.rotate.z
        translate:
          x: -step.translate.x
          y: -step.translate.y
          z: -step.translate.z
        scale: 1 / step.scale

      # Check if the transition is zooming in or not.
      #
      # This information is used to alter the transition style:
      # when we are zooming in - we start with move and rotate transition
      # and the scaling is delayed, but when we are zooming out we start
      # with scaling down and move and rotation are delayed.
      zoomin = target.scale >= this.currentState.scale

      duration = toNumber(duration, config.transitionDuration)
      delay = (duration / 2)

      targetScale = target.scale * windowScale

      # Now we alter transforms of `root` and `canvas` to trigger transitions.
      #
      # And here is why there are two elements: `root` and `canvas` - they are
      # being animated separately:
      # `root` is used for scaling and `canvas` for translate and rotations.
      # Transitions on them are triggered with different delays (to make
      # visually nice and 'natural' looking transitions), so we need to know
      # that both of them are finished.
      css(this.root,
        # to keep the perspective look similar for different scales
        # we need to 'scale' the perspective, too
        transform: perspective(config.perspective / targetScale) + scale(targetScale)
        transitionDuration: "#{duration}ms"
        transitionDelay: "#{(if zoomin then delay else 0)}ms"
      )

      css(this.canvas,
        transform: rotate(target.rotate, true) + translate(target.translate)
        transitionDuration: "#{duration}ms"
        transitionDelay: "#{(if zoomin then 0 else delay)}ms"
      )

      # Here is a tricky part...
      #
      # If there is no change in scale or no change in rotation and translation, it means there was actually
      # no delay - because there was no transition on `root` or `canvas` elements.
      # We want to trigger `impress:stepenter` event in the correct moment, so here we compare the current
      # and target values to check if delay should be taken into account.
      #
      # I know that this `if` statement looks scary, but it's pretty simple when you know what is going on
      # - it's simply comparing all the values.
      if (currentState.scale == target.scale ||
          (currentState.rotate.x == target.rotate.x && currentState.rotate.y == target.rotate.y &&
           currentState.rotate.z == target.rotate.z && currentState.translate.x == target.translate.x &&
           currentState.translate.y == target.translate.y && currentState.translate.z == target.translate.z))
        delay = 0

      # store current state
      this.currentState = target
      el

  )()
