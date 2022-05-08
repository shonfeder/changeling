open Containers
open Changeling

let run : Fpath.t -> string -> (unit, _) Kwdcmd.cmd_result =
 fun changelog version ->
  let open Result.Infix in
  let* content = Bos.OS.File.read changelog in
  let* model = Model.parse content |> Result.map_err (fun m -> `Msg m) in
  model
  |> Model.release ~version
  |> Model.to_string
  |> Bos.OS.File.write changelog
