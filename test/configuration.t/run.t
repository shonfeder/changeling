Errors
======

Trying to load from a non-existent file reports an error

  $ changeling format --config non-existent-config CHANGES.md
  error: configuration file non-existent-config cannot be found
  [1]

Loading invalid configuration reports an error

  $ changeling format --config invalid-config CHANGES.md
  error: invalid configuration in file invalid-config
  [1]

Loading invalid s-expression in file reports an error

  $ changeling format --config invalid-sexp-config CHANGES.md
  error: invalid s-expression in configuration file invalid-sexp-config
  [1]

Success
=======

Running without configuration file results in default config

  $ changeling release CHANGES.md 0.0.1 && cat CHANGES.md
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
  $ changeling release CHANGES.md 0.0.1 && cat CHANGES.md
  # Changelog
  
  ## Unreleased
  ### Foo
  ### Bar
  ### Baz
  ## 0.0.1

Configuration source can be set via CLI

  $ cp CHANGES.md.template CHANGES.md
  $ changeling release --config valid-config-file CHANGES.md 0.0.1 && cat CHANGES.md
  # Changelog
  
  ## Unreleased
  ### Features
  ### Bug fixes
  ### Documentation
  ## 0.0.1
