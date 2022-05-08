open Kwdcmd

let fpath_conv = Arg.(conv (Fpath.of_string, Fpath.pp))

let format =
  cmd
    ~name:"format"
    ~doc:"Parse a changelog to validate or fix its formatting."
    ~man:
      [ `P
          "If the structure of the document is invalid, results in an exit \
           code of [1]."
      ; `P
          "If called with --fix, formatting errors are corrected overwriting \
           the supplied file.\n\
           Otherwise, formatting errors reslut in an exit code of [3]."
      ]
  @@ (* TODO: Should this be configurable? *)
  let+ file =
    Required.pos
      "CHANGELOG"
      ~doc:"The changelog file to"
      ~nth:0
      ~conv:fpath_conv
      ()
  and+ fix =
    Optional.flag
      ~flags:[ "fix"; "f" ]
      ~doc:"overwrite file with fixed formatting, if needed"
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
