# The Range object attempts to normalize browser differences.
# W3C browsers (including IE9+) use a DOM-base model to handle ranges.
# IE7/8 browsers use a text-based model to handle ranges.
#
# STATIC FUNCTIONS:
# getBlankRange(): creates a new range
# getRangeFromSelection(): gets the range from the current selection
# getRangeFromElement(el): gets the range that encompases the given el
#
# PUBLIC FUNCTIONS:
# These functions query the state of the range:
# isCollapsed(): is the selection a caret
# isImageSelected(): is an image selected
# getCoordinates(): gets the coordinates of the range
# getParentElement() : gets parent element of the range
#
# These functions manipulate the range.
# collapse(start): collapse range to start or end (returns this)
# select([range]): selects the given range or itself
# unselect(): unselects the range
# selectEndOfElement(el): selects the inside of the end of el (IE is not supported)
# selectEndOfTableCell(cell): selects the inside of the end of cell
#
# These functions modify the content.
# paste(arg): pastes the given node or html
# surroundContents(el): surrounds the range with the given el
# remove: removes the contents of the range
#
# Range Intro from QuirksMode:
# http://www.quirksmode.org/dom/range_intro.html
define ["jquery.custom", "core/helpers", "core/range/range.module", "core/range/range.coordinates"], ($, Helpers, Module, Coordinates) ->
  class Range
    # Use this to represent the escape error in getParentElement.
    @EDITOR_ESCAPE_ERROR: new Object(),

    #
    # STATIC FUNCTIONS
    #

    # Get a brand new range.
    @getBlankRange: ->
      throw "Range.getBlankRange() needs to be overridden with a browser specific implementation"

    # Gets the currently selected range.
    @getRangeFromSelection: ->
      throw "Range.getRangeFromSelection() needs to be overridden with a browser specific implementation"

    # Get a range that surrounds the el.
    @getRangeFromElement: (el) ->
      throw "Range.getRangeFromElement() needs to be overridden with a browser specific implementation"

    # el: Editable element
    # arg:
    #   - window: the range is the current selection
    #   - element: the range surrounds the element
    #   - range: the range is the given range
    #   - nothing: the range is a new range
    constructor: (@el, arg) ->
      throw "new Range() is missing argument el" unless @el
      throw "new Range() el is not an element" unless Helpers.isElement(@el)
      switch Helpers.typeOf(arg)
        when "window" then @range = Range.getRangeFromSelection()
        when "element" then @range = Range.getRangeFromElement(arg)
        else @range = arg or Range.getBlankRange()

    #
    # QUERY RANGE STATE FUNCTIONS
    #

    # Is the selection a caret.
    isCollapsed: ->
      throw "#isCollapsed() needs to be overridden with a browser specific implementation"

    # Is an image selected.
    isImageSelected: ->
      throw "#isImageSelected() needs to be overridden with a browser specific implementation"

    # Get the coordinates of the range.
    #
    # NOTE:
    # Each browser has a different implementation to return the coordinates.
    #
    # The original solution attempted to solve this in a general way. It
    # inserted a span where the range was and grabbed the coordinates of the
    # span. Then it destroyed the span. However, this posed two problems:
    # 1. When the range was not collapsed, the span would replace whatever was
    # selected.
    # 2. It used Editor.Range.pasteNode() which calls range.focus(). this made
    # IE jump up and down due to the focus.
    # TODO: Problem #2 is invalid. range.focus() doesn't exist and #pasteNode()
    # doesn't call #focus().
    #
    # The second solution attempted to account for an uncollapsed range in a
    # general way by
    # 1. Save the range
    # 2. Collapse to the beginning and find the coordinates using the span
    # 3. Reselect the saved range
    # 4. Collapse to the end and find the coordinates using the span
    # 5. Reselect the saved range
    # Unfortunately, there were two problems:
    # 1. IE still exhibited the jumping due to range.focus().
    # TODO: Problem #1 is invalid. range.focus() doesn't exist.
    # 2. When reselecting the saved range, the W3C browsers lost which
    # direction the selection was made. It always set the selection to be
    # selecting forwards. Hence, if you attempted to continue selecting
    # backwards, it would lose your previous selection and start over again.
    # Note that IE retained memory of which way the selection was going.
    #
    # The final solution implements a solution for each browser and leverages
    # the tools available to each browser and takes into consideration the
    # quirks each browser exhibits.
    # Note that the final solution for Firefox does not return left and right
    # coordinates.
    getCoordinates: ->
      throw "#getCoordinates() needs to be overridden with a browser specific implementation"

    # Finds the first parent element from the range that matches the argument.
    # The match can be a function or a CSS pattern like "a[name=mainlink]". If
    # you want to escape the lookup early, throw Range.EDITOR_ESCAPE_ERROR in
    # the function.
    getParentElement: (match) ->
      switch Helpers.typeOf(match)
        when "function" then matchFn = match
        when "string" then matchFn = (el) -> $(el).filter(match).length > 0
        when "null" then matchFn = -> true
        when "undefined" then matchFn = -> true
        else throw "invalid type for match"
      el = @getImmediateParentElement()
      return null unless el
      try
        while true
          if el == @el or el == document.body
            # If we are at the top el, then we are done. No match.
            el = null
            break
          else if matchFn(el)
            # If match is true, then return it.
            break
          else
            # Else keep searching parents.
            el = el.parentNode
      catch e
        if e == Range.EDITOR_ESCAPE_ERROR
          el = null
        else
          throw e
      el

    #
    # MANIPULATE RANGE FUNCTIONS
    #

    # If start is true, collapses to start of range.
    # Otherwise collapses to end of range.
    collapse: (start) ->
      @range.collapse(start)
      this

    # Select the given range or its own range if none given.
    select: (range) ->
      throw "#select() needs to be overridden with a browser specific implementation"

    # Unselects the range.
    unselect: ->
      throw "#unselect() needs to be overridden with a browser specific implementation"

    # Move selection to the inside of the end of the element.
    #
    # NOTE: The corresponding IE implementation is broken. This only works in
    # W3C.
    selectEndOfElement: (el) ->
      throw "#selectEndOfElement() needs to be overridden with a browser specific implementation"

    # Move selection to the end of a <td> or <th>.
    selectEndOfTableCell: (cell) ->
      throw "#selectEndOfTableCell() needs to be overridden with a browser specific implementation"

    #
    # MODIFY RANGE CONTENT FUNCTIONS
    #

    # Paste the given arg.
    # arg:
    #   - HTML string: pastes the HTML string as is
    #   - element: pastes the element
    #
    # NOTE: The browser may normalize the content.
    paste: (arg) ->
      switch Helpers.typeOf(arg)
        when "string" then @pasteHTML(arg)
        when "element" then @pasteNode(arg)
        else throw "Don't know how to paste this type of arg"

    # Surround range with element.
    surroundContents: (el) ->
      throw "#surroundContents() needs to be overridden with a browser specific implementation"

    # Remove the contents of the range.
    remove: ->
      throw "#remove() needs to be overridden with a browser specific implementation"

  Helpers.extend(Range, Module.static)
  Helpers.include(Range, Module.instance)
  Helpers.include(Range, Coordinates)

  return Range
