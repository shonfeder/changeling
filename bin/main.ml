open Kwdcmd

let fpath_conv = Arg.(conv (Fpath.of_string, Fpath.pp))

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
  let+ file =
    Required.pos
      "CHANGELOG"
      ~doc:"The changelog file to format"
      ~nth:0
      ~conv:fpath_conv
      ()
  and+ fix =
    Optional.flag
      ~flags:[ "fix"; "f" ]
      ~doc:"overwrite file with normalized formatting, if needed"
      ()
  in
  Format.run file fix


let main () =
  Exec.commands
    ~name:"changeling"
    ~version:"0.0.1"
    ~doc:"Harmonize changelogs"
    [ format ]

let () = main ()
