'use babel';
'use strict';

path = require 'path';
fs   = require 'fs';
glob = require 'glob';
child_process = require 'child_process';

module.exports =
  _off: []
  _projectPaths: []

  activate: (state) ->
    require('atom-package-deps').install('rock')
    @_off.push atom.workspace.observeTextEditors (editor) =>
      @_off.push editor.onDidChangePath =>
        @_tryToSetGrammar editor
      @_tryToSetGrammar editor

    @_projectPaths = atom.project.getPaths();
    @refreshSyskitTargets(workspacePath) for workspacePath in @_projectPaths
    atom.project.onDidChangePaths (newProjectPaths) =>
      addedPaths   = newProjectPaths.filter el ->
          projectPaths.indexOf(el) == -1
      removedPaths = projectPaths.filter el ->
          newProjectPaths.indexOf(el) == -1
      @_projectPaths = newProjectPaths;
      @refreshSyskitTargets(workspacePath) for workspacePath in addedPaths

  refreshSyskitTargets: (workspacePath) ->
      glob.sync(path.join(workspacePath, 'bundles', '*')).map (bundlePath) =>
          @discoverBundle(bundlePath).map (robotConfig) =>
              @defineAtomCommand(workspacePath, robotConfig)

  defineAtomCommand: (workspacePath, config) ->
      commandName = "syskit:start-IDE-#{config.bundleName}-#{config.robotName}"
      atom.commands.add 'atom-workspace', commandName, ->
          envsh = '"' + path.join(workspacePath, 'env.sh') + '"'
          child_process.spawn "bash -c '. #{envsh}; ruby -S syskit ide -r#{config.robotName}'", stdio: 'ignore', detached: false, shell: true, cwd: config.bundlePath
      commandName

  discoverBundle: (bundlePath) ->
      robots     = glob.sync(path.join(bundlePath, 'config', 'robots', '*.rb'))
      bundleName = path.basename(bundlePath)
      robots.map (robotConfigPath) ->
          { bundlePath: bundlePath, bundleName: bundleName, robotName: path.basename(robotConfigPath, '.rb') }

  deactivate: ->
    o?() for o in @_off
    @_onceAllPackagesActivated.dispose()
    @_onceAllPackagesActivated = null

  _tryToSetGrammar: (editor) ->
    fullPath = editor.getPath()
    return unless fullPath?
    filename = path.basename fullPath
    if filename.match(/\.orogen$/)
        scopeName = 'source.ruby';
    else if filename.match(/\.osdeps$/)
        scopeName = 'source.yaml';
    else if filename == 'manifest' && path.basename(path.dirname(fullPath)) == 'autoproj'
        scopeName = 'source.yaml';

    if scopeName?
        g = atom.grammars.grammarForScopeName scopeName
        if g?
            editor.setGrammar g
