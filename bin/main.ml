open Kwdcmd

let fpath_conv = Arg.(conv (Fpath.of_string, Fpath.pp))

let changelog ?(name = "CHANGELOG") ?(nth=0) () =
  Required.pos
    name
    ~doc:"The changelog file to format"
    ~nth
    ~conv:fpath_conv
    ()

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
  @@ (* TODO: Should this be configurable? *)
  let+ changelog = changelog ()
  and+ fix =
    Optional.flag
      ~flags:[ "fix"; "f" ]
      ~doc:"overwrite file with normalized formatting, if needed"
      ()
  in
  Format.run changelog fix

let release =
  cmd ~name:"release" ~doc:"Update the CHANGELOG for the release of VERSION"
  @@ let+ changelog = changelog ()
     and+ version =
       Required.pos
         "VERSION"
         ~doc:"The version to be released"
         ~nth:1
         ~conv:Arg.string
         ()
     in
     Release.run changelog version

let version =
  cmd
    ~name:"version"
    ~doc:"Extracts just the changes for VERSION from CHANGELOG"
  @@ let+ changelog = changelog ()
     and+ version =
       Required.pos
         "VERSION"
         ~doc:"The version to be released"
         ~nth:1
         ~conv:Arg.string
         ()
     in
     Version.run changelog version

let merge =
  cmd ~name:"merge" ~doc:"Merge two changelogs into stdout"
  @@ let+ changelog_a = changelog ~name:"CHANGELOG_A" ~nth:0 ()
     and+ changelog_b = changelog ~name:"CHANGELOG_B" ~nth:1 () in
     Merge.run changelog_a changelog_b

let main () =
  Exec.commands
    ~name:"changeling"
    ~version:"0.0.1"
    ~doc:"Harmonize changelogs"
    [ format; release; version; merge ]

let () = main ()
