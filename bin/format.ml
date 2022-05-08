open Containers
open Changeling

let run : Fpath.t -> bool -> (unit, _) Kwdcmd.cmd_result =
  fun changelog _fix ->
  let open Result.Infix in
  let* contents = Bos.OS.File.read changelog in
  match Model.parse contents with
  | Error msg -> Error (`Msg ("[invalid format] " ^ msg))
  | Ok _ -> Ok ()
