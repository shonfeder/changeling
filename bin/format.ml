open Containers
open Changeling

let run : Fpath.t -> bool -> (unit, _) Kwdcmd.cmd_result =
 fun changelog fix ->
  let open Result.Infix in
  let* contents = Bos.OS.File.read changelog in
  match Model.parse contents with
  | Error msg -> Error (`Msg ("[invalid format] " ^ msg))
  | Ok t      ->
      let formatted = Model.to_string t in
      if String.equal contents formatted then
        Ok ()
      else if fix then
        Bos.OS.File.write changelog formatted
      else (
        print_string formatted;
        Printf.eprintf "error: format is not normalized; rerun with --fix";
        exit 3
      )
