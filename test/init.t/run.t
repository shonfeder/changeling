Errors
======

Running outside of a git repo produces a warning

  $ changeling init NONGIT_CHANGES.md
  warning: not running from root of git repository, git will not be configured

  $ ls -a
  .
  ..
  NONGIT_CHANGES.md

  $ rm NONGIT_CHANGES.md

Success
=======

We need to be working in the root of a git repo to set up the git config

  $ git init -b trunk .
  Initialized empty Git repository in $TESTCASE_ROOT/.git/

Initialize the repo with the expected configuration files

  $ changeling init CHANGES.md

  $ ls -a
  .
  ..
  .git
  .gitattributes
  CHANGES.md

The git config has the custom drier configured

  $ tail -n 6 .git/config
  
  # CHANGELING CONFIG START
  [merge "changeling"]
      name = changeling: changelog merge driver
      driver = changeling merge %A %B --out %A
  # CHANGELING CONFIG END

The gitattributes configures the custom driver for the changelog

  $ cat .gitattributes
  
  # CHANGELING CONFIG START
  CHANGES.md merge=changeling
  # CHANGELING CONFIG END

The generated changelog has the expected content

  $ cat CHANGES.md
  # Changelog
  
  All notable changes to this project will be documented in this file.
  
  The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
  and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
  
  ## Unreleased
  ### Added
  ### Changed
  ### Deprecated
  ### Removed
  ### Fixed
  ### Security

Init is idempotent, and running it a second time is a noop

  $ changeling init CHANGES.md

  $ grep .git/config CHANGELING
  grep: CHANGELING: No such file or directory
  [2]

  $ cat .gitattributes
  
  # CHANGELING CONFIG START
  CHANGES.md merge=changeling
  # CHANGELING CONFIG END

  $ cat CHANGES.md
  # Changelog
  
  All notable changes to this project will be documented in this file.
  
  The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
  and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
  
  ## Unreleased
  ### Added
  ### Changed
  ### Deprecated
  ### Removed
  ### Fixed
  ### Security


MERGE DRIVER
------------

We'll now prodcue a merge conflit, to verify that the merge driver fallback is
configured correctly.

First, set up a simple changelog

  $ printf "# Changelog\n\n## Unreleased\n\n### Added\n\n- Change 1\n" > CHANGES.md

Commit the changes

  $ git add . && git commit -m "Add changeling config" >/dev/null 2>&1

Checkout a new branach and add a change

  $ git checkout -b conflict
  Switched to a new branch 'conflict'
  $ echo "- Change 2" >> CHANGES.md
  $ git add . && git commit -m "Add change 2" >/dev/null 2>&1

Checkout the trunk again, and add a different change

  $ git checkout trunk
  Switched to branch 'trunk'
  $ echo "- Change 3" >> CHANGES.md
  $ git add . && git commit -m "Add change 3" >/dev/null 2>&1

Merge the conflicting branch, showing that the changeling driver kicks in

  $ git merge conflict -m "Merge changes"
  $ cat CHANGES.md
