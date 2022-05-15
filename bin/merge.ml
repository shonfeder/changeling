open Containers

let run :
    Fpath.t -> Fpath.t option -> Config.options -> (unit, _) Kwdcmd.cmd_result =
 fun other_changelog dest { model = (module Model); changelog } ->
  let open Result.Infix in
  let* a_content = Bos.OS.File.read changelog in
  let* a = Model.parse a_content in
  let* b_content = Bos.OS.File.read other_changelog in
  let* b = Model.parse b_content in
  let* c = Model.merge a b >|= Model.to_string in
  match dest with
  | None     -> Ok (print_string c)
  | Some out -> Bos.OS.File.write out c
