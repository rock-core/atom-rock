'use babel';
'use strict';

{basename} = require 'path';

module.exports =
  _off: []

  activate: (state) ->
    require('atom-package-deps').install('rock')
    @_off.push atom.workspace.observeTextEditors (editor) =>
      @_off.push editor.onDidChangePath =>
        @_tryToSetGrammar editor
      @_tryToSetGrammar editor

  deactivate: ->
    o?() for o in @_off
    @_onceAllPackagesActivated.dispose()
    @_onceAllPackagesActivated = null

  _tryToSetGrammar: (editor) ->
    fullPath = editor.getPath()
    return unless fullPath?
    filename = basename fullPath
    if filename.match(/\.orogen$/)
        scopeName = 'source.ruby';

    if scopeName?
        g = atom.grammars.grammarForScopeName scopeName
        if g?
            editor.setGrammar g
