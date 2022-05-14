open Containers
open Changeling

let run : (module Model.S) -> Fpath.t -> string -> (unit, _) Kwdcmd.cmd_result =
  fun (module Model) changelog version ->
  let open Result.Infix in
  let* content = Bos.OS.File.read changelog in
  let* model = Model.parse content in
  model
  |> Model.release ~version
  |> Model.to_string
  |> Bos.OS.File.write changelog
