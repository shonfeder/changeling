Errors
======

On empty changelog

  $ changeling format empty_changes.md
  error: [invalid format] empty changelog
  [1]

On missing title

  $ changeling format missing_title.md
  error: [invalid format] expected '# Some title' but found '## Not an H1 title'
  [1]

On missing "Unreleased" section

  $ changeling format missing_unreleased.md
  error: [invalid format] expected '## Unreleased' section but found '## 1.1.1 - 2022-05-08'
  [1]

On invald change sections

  $ changeling format invalid_changes.md
  error: [invalid format] expected change header but found '### Invalid change kind'
  [1]

Success
=======

Validate the formatting of a valid changelog

  $ changeling format CHANGES.md
