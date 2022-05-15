Errors
======

Trying to load from a non-existent file reports an error

  $ changeling format --config non-existent-config
  error: configuration file non-existent-config cannot be found
  [1]

Loading invalid configuration reports an error

  $ changeling format --config invalid-config
  error: invalid configuration in file invalid-config
  [1]

Loading invalid s-expression in file reports an error

  $ changeling format --config invalid-sexp-config
  error: invalid s-expression in configuration file invalid-sexp-config
  [1]

Success
=======

Running without configuration file results in default config

  $ changeling release 0.0.1 && cat CHANGES.md
  # Changelog
  
  ## Unreleased
  ### Added
  ### Changed
  ### Deprecated
  ### Removed
  ### Fixed
  ### Security
  ## 0.0.1

Configuration is read from a .changeling file, if it's present

  $ cp CHANGES.md.template CHANGES.md
  $ echo "((changes (Foo Bar Baz)))" > .changeling
  $ changeling release 0.0.1 && cat CHANGES.md
  # Changelog
  
  ## Unreleased
  ### Foo
  ### Bar
  ### Baz
  ## 0.0.1
  A section from the default CHANGES.md
  

Configuration source can be set via CLI

  $ cp CHANGES.md.template CHANGES.md
  $ changeling release 0.0.1 --config valid-config-file && cat CHANGES.md
  # Changelog
  
  ## Unreleased
  ### Features
  ### Bug fixes
  ### Documentation
  ## 0.0.1
  A section from the default CHANGES.md
  

Changelog can be configued from a config file

  $ changeling version Unreleased --config=changelog-config
  ## Unreleased
  The unreleased section from the CONFIGURED_CHANGELOG.md.
  
  - Nothing to see here
  
Setting the changelog via CLI overrides the config file

  $ cp CHANGES.md.template CHANGES.md
  $ changeling version Unreleased --config=changelog-config --changelog=CHANGES.md
  ## Unreleased
  A section from the default CHANGES.md
  
