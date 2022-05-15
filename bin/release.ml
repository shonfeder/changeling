open Containers

let run : string -> Config.options -> (unit, _) Kwdcmd.cmd_result =
 fun version { model = (module Model); changelog } ->
  let open Result.Infix in
  let* content = Bos.OS.File.read changelog in
  let* model = Model.parse content in
  model
  |> Model.release ~version
  |> Model.to_string
  |> Bos.OS.File.write changelog
