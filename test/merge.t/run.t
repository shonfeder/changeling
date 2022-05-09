Can merge two compatible files

  $ changeling merge changes_a.md changes_b.md
  # Changelog
  
  Some summary data.
  
  ## Unreleased
  ### Added
  - Cooking
  - Hair
  - Sports
  
  ### Changed
  - Altered
  
  ### Deprecated
  ### Removed
  - Clouds
  - Dishes
  - Plants
  
  ### Fixed
  ### Security
  ## 1.1.1
  Version summary
  
  ### Added
  - Bar
  - Baz
  - Foo
  
  ### Removed
  - Zoo
  - Zar
  - Zaz
  
  ### Fixed
  - Some stuff
  
Trying to merge incompatible files produces an error

  $ changeling merge changes_a.md title_conflict.md
  error: titles conflict: '# Changelog' <> '# Conflicting title'
  [1]

  $ changeling merge changes_a.md summary_conflict.md
  error: summaries conflict: 'Some summary data.' <> 'A conflicting summary.'
  [1]

  $ changeling merge changes_a.md version_conflict.md
  error: versions conflict: '## 1.1.1' <> '## 1.1.2'
  [1]

  $ changeling merge changes_a.md release_summary_conflict.md
  error: release summaries conflict: 'Version summary' <> 'Version summary conflicts.'
  [1]
