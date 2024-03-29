open Containers

let run : string -> Config.options -> (unit, _) Kwdcmd.cmd_result =
 fun version { model = (module Model); changelog } ->
  let open Result.Infix in
  let* content = Bos.OS.File.read changelog in
  let* model = Model.parse content in
  let+ release =
    Model.get_version ~version model
    |> Option.to_result
         (Rresult.R.msgf
            "version %s is not recorded in %a"
            version
            Fpath.pp
            changelog)
  in

  Model.Release.to_md release |> Omd.to_markdown |> print_string
