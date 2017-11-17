# Common Atom setup for Rock

This package adds support to interact with a Rock system.

## Installation

The best way to install this package is through Atom's integrated package
manager. Alternatively, you may install it from the command line with:

~~~
apm install rock
~~~

## What does it do ?

- it tries to setup the right scopes for rock-specific files that have
  non-standard extensions. For instance, it sets up the ruby language
  for `.orogen` files, or YAML for the autoproj files that are in YAML
- provides the "Start Syskit IDE" action for bundle packages

This package also allows to install other packages that are useful within a
Rock system, such as the `build-autoproj` package. It provides two commands
to this effect, that can be found in the Packages>Rock menu.

- "Rock Install Default Packages" will install packages that are deemed useful in a
  Rock system.
- "Rock Apply Default Configuration" will install packages, but also change Atom's
  configuration to fit a Rock system better
