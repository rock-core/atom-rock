'use babel';
'use strict';

path = require 'path';
fs   = require 'fs';
glob = require 'glob';
child_process = require 'child_process';
{ CompositeDisposable } = require 'atom';

module.exports =
  _disposables: new CompositeDisposable();
  _projectPaths: []
  _projectCommands: new Map()

  activate: (state) ->
      @_disposables.add atom.commands.add 'atom-workspace', 'rock:install-default-packages', =>
          require('atom-package-deps').install('rock')
      @_disposables.add atom.commands.add 'atom-workspace', 'rock:apply-default-configuration', =>
          require('atom-package-deps').install('rock')
          atom.config.set 'atom-ide-ui.use.atom-ide-diagnostic-ui', false
          atom.config.set 'build.refreshOnShowTargetList', true
          atom.config.set 'editor.atomicSoftTabs', false
          atom.config.set 'editor.tabLength', 4
          atom.config.set 'tree-view.hideIgnoredNames', true
          atom.config.set "linter-ui-default.decorateOnTreeView", "Files and Directories"
          atom.config.set "linter-ui-default.panelRepresents", "Entire Project"
          atom.config.set "linter-ui-default.showPanel", true

      @_disposables.add atom.packages.onDidActivateInitialPackages =>
          @_disposables.add atom.workspace.observeTextEditors (editor) =>
              @_disposables.add editor.onDidChangePath =>
                  @tryToSetGrammar editor
              @tryToSetGrammar editor

      @refreshProjectPaths(atom.project.getPaths())
      @_disposables.add atom.project.onDidChangePaths (newProjectPaths) =>
          @refreshProjectPaths(newProjectPaths)

  deactivate: ->
      @_disposables.dispose()

  refreshProjectPaths: (newProjectPaths) ->
      addedPaths   = newProjectPaths.filter (el) =>
          @_projectPaths.indexOf(el) == -1
      removedPaths = @_projectPaths.filter (el) ->
          newProjectPaths.indexOf(el) == -1
      @_projectPaths = newProjectPaths;
      removedPaths.forEach (bundlePath) =>
          @_projectCommands.get(bundlePath).dispose()
          @_projectCommands.delete(bundlePath)
      addedPaths.forEach (bundlePath) =>
          projectDisposables = new CompositeDisposable()
          @_projectCommands.set(bundlePath, projectDisposables)
          @refreshSyskitTargets(bundlePath, projectDisposables)

  refreshSyskitTargets: (bundlePath, disposables) ->
      @discoverBundle(bundlePath).forEach (robotConfig) =>
          disposables.add(@defineAtomCommand(bundlePath, robotConfig))

  defineAtomCommand: (bundlePath, config) ->
      commandName = "syskit:start-IDE-#{config.bundleName}-#{config.robotName}"
      workspacePath = path.dirname(path.dirname(bundlePath))
      autoprojExePath = path.join(workspacePath, '.autoproj', 'bin', 'autoproj')
      atom.commands.add 'atom-workspace', commandName, ->
          envsh = '"' + path.join(bundlePath, '..', '..', 'env.sh') + '"'
          run_ide = child_process.spawn autoprojExePath, ['exec', 'syskit', 'ide', "-r#{config.robotName}"],
              { cwd: config.bundlePath }

          run_ide.on 'close', (code) ->
              if code != 0
                  atom.notifications.addError("Autoproj: Failed to start the Syskit IDE: #{run_ide.stderr}")

  discoverBundle: (bundlePath) ->
      robots     = glob.sync(path.join(bundlePath, 'config', 'robots', '*.rb'))
      bundleName = path.basename(bundlePath)
      robots.map (robotConfigPath) ->
          { bundlePath: bundlePath, bundleName: bundleName, robotName: path.basename(robotConfigPath, '.rb') }


  tryToSetGrammar: (editor) ->
      fullPath = editor.getPath()
      return unless fullPath?
      filename = path.basename fullPath
      if filename.match(/\.orogen$/)
          scopeName = 'source.ruby';
      else if filename.match(/\.autobuild$/)
          scopeName = 'source.ruby';
      else if filename.match(/\.osdeps$/)
          scopeName = 'source.yaml';
      else if filename == 'manifest' && path.basename(path.dirname(fullPath)) == 'autoproj'
          scopeName = 'source.yaml';

      if scopeName?
          g = atom.grammars.grammarForScopeName(scopeName)
          if g?
              editor.setGrammar(g)
