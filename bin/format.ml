open Containers
open Changeling

module Make (Model : Model.S) = struct
  let run : Fpath.t -> bool -> (unit, _) Kwdcmd.cmd_result =
   fun changelog fix ->
    let open Result.Infix in
    let* contents = Bos.OS.File.read changelog in
    let* t = Model.parse contents in
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
end
