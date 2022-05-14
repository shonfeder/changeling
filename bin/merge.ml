open Containers
open Changeling

let run :
       (module Model.S)
    -> Fpath.t
    -> Fpath.t
    -> Fpath.t option
    -> (unit, _) Kwdcmd.cmd_result =
 fun (module Model) changelog_a changelog_b dest ->
  let open Result.Infix in
  let* a_content = Bos.OS.File.read changelog_a in
  let* a = Model.parse a_content in
  let* b_content = Bos.OS.File.read changelog_b in
  let* b = Model.parse b_content in
  let* c = Model.merge a b >|= Model.to_string in
  match dest with
  | None     -> Ok (print_string c)
  | Some out -> Bos.OS.File.write out c
