Can fetch unreleased version

  $ changeling version Unreleased --changelog=changes.md
  ## Unreleased
  ### Added
  - Thing 1
  - Thing 2
  
  ### Removed
  - Stuff 1
  - Stuff 2
  
Can fetch released version

  $ changeling version 0.1.0 --changelog=changes.md
  ## 0.1.0
  ### Fixed
  - Fixed 1
  - Fixed 2
  
  ### Security
  - Security 1
  - Security 2
  

Reports appropriate error when version is not in changelog

  $ changeling version non-version --changelog=changes.md
  error: version non-version is not recorded in changes.md
  [1]
