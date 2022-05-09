open Containers
open Changeling

let run : Fpath.t -> Fpath.t -> (unit, _) Kwdcmd.cmd_result =
 fun changelog_a changelog_b ->
  let open Result.Infix in
  let* a = Bos.OS.File.read changelog_a >>= Model.parse in
  let* b = Bos.OS.File.read changelog_b >>= Model.parse in
  Model.merge a b >|= Model.to_string >|= print_string
