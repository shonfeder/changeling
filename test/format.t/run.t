Errors
======

On empty changelog

  $ changeling format empty_changes.md
  error: [invalid structure] empty changelog
  [1]

On missing title

  $ changeling format missing_title.md
  error: [invalid structure] expected '# Some title' but found '## Not an H1 title'
  [1]
On missing "Unreleased" section

  $ changeling format missing_unreleased.md
  error: [invalid structure] expected '## Unreleased' section but found '## 1.1.1 - 2022-05-08'
  [1]

On invald change sections

  $ changeling format invalid_changes.md
  error: [invalid struture] expected change header but found '### Invalid change kind'
  [1]

Success
=======

Report unnormalized formatting of a valid changelog and print corrected format to stdout

  $ changeling format CHANGES.md > CHANGES_CORRECTED.md
  error: format is not normalized; rerun with --fix
  [3]

  $ head CHANGES_CORRECTED.md
  # Changelog
  
  All notable changes to this project will be documented in this file.
  
  The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
  and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
  
  ## [Unreleased]
  ## [1.0.0] - 2017-06-20
  ### Added

Running on a normalized changelog succeeds quietly

  $ changeling format CHANGES_CORRECTED.md

Running with `--fix` will fix formatting of the file in place

  $ cat unordered_changes.md
  # Changelog
  
  Here is the summary.
  
  ## Unreleased
  ### Security
  
  - Security
  - Stuff
  
  ### Removed
  
  - Fruit
  - Cheese
  - Blah
  
  ### Fixed
  
  - Blah
  - Flip
  - Flop
  
  ### Added
  
  - This
  - Section
  - Should
  - Be
  - First
  $ changeling format --fix unordered_changes.md
  $ cat unordered_changes.md
  # Changelog
  
  Here is the summary.
  
  ## Unreleased
  ### Added
  - This
  - Section
  - Should
  - Be
  - First
  
  ### Removed
  - Fruit
  - Cheese
  - Blah
  
  ### Fixed
  - Blah
  - Flip
  - Flop
  
  ### Security
  - Security
  - Stuff
  
