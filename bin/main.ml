open Kwdcmd
open Util

let ( >>= ) = Containers.Result.Infix.( >>= )

let format =
  cmd
    ~name:"format"
    ~doc:"Parse a changelog to validate or fix its formatting."
    ~man:
      [ `P "If the structure of the document is invalid, exit with code [1]."
      ; `P
          "If the formatting in $(b,CHANGELOG) is not normalized, and the \
           command is invoked with $(b,--fix), then $(b,CHANGELOG) will be \
           overwritten with the normalized formatting.\n\
           Otherwise, a normalized version of the file content is printed to \
           stdout and the tool exists with code [3]."
      ; `P
          "Otherwise, if the structure is valid and the formatting normalized, \
           the command is a noop and exits with [0]."
      ]
  @@ let+ fix =
       Optional.flag
         ~flags:[ "fix"; "f" ]
         ~doc:"overwrite file with normalized formatting, if needed"
         ()
     and+ o = Config.options in
     o >>= Format.run fix

let release =
  cmd ~name:"release" ~doc:"Update the CHANGELOG for the release of VERSION"
  @@ let+ version =
       Required.pos
         "VERSION"
         ~doc:"The version to be released"
         ~nth:0
         ~conv:Arg.string
         ()
     and+ o = Config.options in
     o >>= Release.run version

let version =
  cmd
    ~name:"version"
    ~doc:"Extracts just the changes for VERSION from CHANGELOG"
  @@ let+ version =
       Required.pos
         "VERSION"
         ~doc:"The version to be extract"
         ~nth:0
         ~conv:Arg.string
         ()
     and+ o = Config.options in
     o >>= Version.run version

let merge =
  cmd ~name:"merge" ~doc:"Merge two changelogs into stdout"
  @@ let+ other_changelog =
       Required.pos
         "OTHER_CHANGELOG"
         ~doc:"The changelog file to format"
         ~nth:0
         ~conv:Fpath.cmdline_conv
         ()
     and+ dest =
       Optional.value
         "DESTINATION"
         ~flags:[ "out"; "o" ]
         ~doc:
           "Destination file to write merge result to. If omitted, writes \
            merged result to stdout"
         ~default:None
         ~conv:Arg.(some Fpath.cmdline_conv)
         ()
     and+ o = Config.options in
     o >>= Merge.run other_changelog dest

let init =
  cmd ~name:"init" ~doc:"Initialize the git config for use with changeling"
  @@ let+ o = Config.options in
     o >>= Init.run

let main () =
  Exec.commands
    ~name:"changeling"
    ~version:"0.0.1"
    ~doc:"Harmonize changelogs"
    [ format; release; version; merge; init ]

let () = main ()
