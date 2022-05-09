# Changeling

Harmonize changelogs without mangling their purpose.

`changeling` follows [keep a changelog](https://keepachangelog.com/en/1.0.0/) in
keeping the focus of the changelog process on human-to-human communication about
salient, observable changes in software. It assumes that the purpose of a
changelog is

>  To make it easier for users and contributors to see precisely what notable
>  changes have been made between each release (or version) of the project.

Where should this kind of communication take place?

Many developers have established a [desire path][] through simple markdown
files, thus the convention that a log of salient changes is recorded in a single
document in a simple, loosely structured format.

Some tools have tried to automate changelog generation by hijacking
communication channels that serve their own distinct purpose, such as commit
messages, pull requests, and issues. We think these communication channels are
already being used for valuable communications between different parties about
different subjects. Instead, changeling follows the desire path.

`changeling` aims to resolve the following problems, without requiring any
changes to the lightweight, document-based changelog process that is so
widespread:

- eliminate merge conflicts resulting from parallel updates to the changelog
- support automated deployment
- provide an unobtrusive way to keep the structure and format of changelog's
  in a normalized form

[desire path]: https://en.wikipedia.org/wiki/Desire_path

## Caveats

- The tool is in prototype stage.
- The merging strategy is currently extremely naive and limited. It works fine
  for the usual changelog format according to my tests, but any fancy stuff
  (like changelogs divided into subcomponents) is currently not supported.
