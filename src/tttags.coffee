
$ = jQuery

ON  = 'ttton'
SEL = 'tttsel'
ACT = 'tttact'

subst = (expr, map) ->
    expr.replace /\#{([^{}]*)}/g, (a, b) ->
        r = map[b]
        if (t = typeof r) == 'string' or t == 'number' then r else a

defaultOpts =
    placeholder : ''
    template    : '<a class="tag">#{tag}</a> '
    className   : 'label label-default'
    allowNew    : true
    source      : ->
    onTagAdd    : ->
    onTagRemove : ->
    onFocus     : ->
    onBlur      : ->

class TTTags

    constructor: (opts) ->
        $.extend this, Backbone.Events
        @opts = $.extend {}, defaultOpts, opts
        @$el = @opts.$el
        @$el.addClass 'tttags'
        @$el.on 'click', @_onClick
        @$el.on 'mousedown', @_onMouseDown
        @$el.on 'focus', @_onFocus
        if @opts.placeholder
            $('<span class="tttplaceholder">').text(@opts.placeholder).appendTo @$el
            @_maybeShowPlaceholder()
        @src = @opts.source

    source: (source) =>
        @$list?.remove()
        @$list = null
        @src = source
        if @isActive()
            @_buildListAndInput()
            @_suggest @$input.text()
        if (tags = @tags()).length
            tags.forEach (tag) => @remove tag unless @inList tag
            @_maybeShowPlaceholder()
        this

    focus: =>
        @_buildListAndInput()
        @$input.attr('contenteditable', true)
        @$input.focus()
        this

    remove: (tag, opts) =>
        opts = opts ? {}
        $el = tag
        unless tag instanceof $
            $el = $('.tag', @$el).filter -> $(this).text() == tag
        if $el?.length
            $el.remove()
            @_trigger 'remove', 'onTagRemove', $el.text(), $el unless opts.silent
        this

    removeLast: =>
        @remove $('.tag', @$el).last()
        this

    has: (tag) =>
        ($('.tag', @$el).filter -> $(this).text() == tag).length > 0

    inList: (tag) =>
        @_buildListAndInput()
        ($('li', @$list).filter -> $(this).text() == tag).length > 0

    add: (tag, opts) =>
        opts = opts ? {}
        return this if @has tag
        return this unless @opts.allowNew or opts.force or (inList = @inList tag)
        $el = $ subst @opts.template, tag:tag
        $el.addClass @opts.className if @opts.className
        $el = $('<span>').append($el).append(' ')
        if @$inputwrap
            @$inputwrap.before($el)
        else
            @$el.prepend $el if $('.tag', @$el).parent().last().after($el).length == 0

        @_trigger 'add', 'onTagAdd', tag, $el, !inList unless opts.silent
        this

    tags: (toSet) =>
        toSet = [toSet] if typeof toSet == 'string'
        if $.isArray toSet
            @tags().forEach (tag) => @remove tag, silent:true
            toSet.forEach (tag) => @add tag, {force:true, silent:true}
            @_maybeShowPlaceholder()
            this
        else
            ($('.tag', @$el).map -> $(this).text()).toArray()

    isActive: =>
        return @$el.hasClass ACT

    destroy: =>
        @$input.off() if @$input
        @$el.off() if @$el
        @$input?.remove()
        @$input = null
        @$list?.remove()
        @$list = null
        @$inputwrap?.remove()
        @$inputwrap = null
        @$el.data('tttags', null)
        @$el = null

    _trigger: (event, callback, tag, el, isNew) =>
        evt =
            type: event
            tags: @tags()
            src: this
        evt.tag = tag if tag
        evt.el = el if el
        evt.isNew = isNew if typeof isNew == 'boolean'
        @trigger event, evt
        cb = @opts[callback]
        cb evt if typeof cb == 'function'

    _buildListAndInput: =>
        unless @$input
            @$inputwrap = $('<span class="tttinputwrap">').appendTo @$el
            @$input = $('<span class="tttinput"/>').appendTo @$inputwrap
            @$input.on 'focus', @_onInputFocus
            @$input.on 'blur', @_onInputBlur
            @$input.on 'keydown', @_onInputKeyDown
            @$input.on 'keyup', @_onInputKeyUp
        return if @$list
        @$list = $('<div class="tttaglist">').appendTo @$inputwrap
        $ol = $('<ol>').appendTo @$list
        s = if typeof @src == 'function' then @src() else []
        s = [] if not $.isArray s
        s.forEach (tag) => $('<li>').text(tag).appendTo $ol

    _suggest: (txt) =>
        if @lastSuggest != txt
            ltxt = txt.toLowerCase()
            $('li', @$list).each (_,el) =>
                $el = $(el)
                $el.toggleClass ON, $el.text().toLowerCase().indexOf(ltxt) == 0
            @lastSuggest = txt
            $sel = $('li.' + SEL, @$list)
            $sel.removeClass SEL unless $sel.hasClass ON
            show = txt.length> 0 and $('li.' + ON, @$list).length > 0
            @$list.toggleClass ON, show

    _listStep: (ev, up) =>
        return unless @$list.hasClass ON
        $sel = $('li.' + SEL, @$list)
        if $sel.length
            if up and (tmp = $sel.prevAll('li.' + ON )).length
                $sel.removeClass(SEL)
                tmp.first().addClass SEL
                ev.preventDefault()
            if not up and (tmp = $sel.nextAll('li.' + ON )).length
                $sel.removeClass(SEL)
                tmp.first().addClass SEL
                ev.preventDefault()
        else
            if up
                $('li.' + ON, @$list).last().addClass SEL
                ev.preventDefault()
            else
                $('li.' + ON, @$list).first().addClass SEL
                ev.preventDefault()
        $sel = $('li.' + SEL, @$list)
        return if $sel.length == 0
        lh = @$list.outerHeight()
        ls = @$list.scrollTop()
        st = $sel[0].offsetTop
        sh = $sel.outerHeight()
        if (st + sh) > (lh + ls)
            @$list.scrollTop (st + sh) - lh
        if (st < ls)
            @$list.scrollTop st

    _doSelect: =>
        $sel = $ 'li.' + SEL, @$list
        if $sel.length
            @add $sel.text(), force:true
        else
            @add @$input.text(), force:false
        @$input.text('')
        @_suggest('')

    _maybeShowPlaceholder: =>
        $('.tttplaceholder', @$el).toggleClass ON, ($('.tag', @$el).length == 0)

    _onMouseDown: (ev) =>
        $t = $(ev.target)
        if (li = $t.closest('li')).length > 0
            $('li.' + SEL, @$list).removeClass SEL
            li.addClass SEL
            @_doSelect()
        ev.preventDefault() if @isActive()

    _onClick: (ev) =>
        $t = $(ev.target)
        @focus()

    _onFocus: (ev) =>
        @focus()
    _onInputFocus: (ev) =>
        return if @isActive()
        @$el.addClass ACT
        @_trigger 'focus', 'onFocus'
    _onInputBlur: (ev) =>
        return if !@isActive()
        @$el.removeClass ACT
        @$input.text('').removeAttr('contenteditable')
        @_suggest('')
        $('li.' + SEL, @$list).removeClass SEL
        @_maybeShowPlaceholder()
        @_trigger 'blur', 'onBlur'
    _onInputKeyDown: (ev) =>
        switch ev.keyCode
            when 13 then ev.preventDefault(); @_doSelect()
            when 27 then @$input.blur()
            when 8
                range = window?.getSelection().getRangeAt(0)
                if range
                    @removeLast() if range.startOffset == range.endOffset == 0
                else
                    @removeLast() if @$input.text() == ''
            when 38 then @_listStep ev, true
            when 40 then @_listStep ev, false
    _onInputKeyUp: (ev) => @_suggest @$input.text()

$.fn.tttags = (action, data) ->
    opts = null
    if $.isPlainObject action
        opts = action
        action = null
    obj = null
    @each (i, el) ->
        $el = $ el
        obj = $el.data 'tttags'
        if !obj
            topts = $.extend({}, opts)
            topts.$el = $el
            $el.data 'tttags', obj = new TTTags(topts)
        obj[action](data) if action
    if action or opts then this else obj
