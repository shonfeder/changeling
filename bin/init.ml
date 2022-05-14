open Containers
open Changeling

let config_marker_start = "# CHANGELING CONFIG START"

let config_marker_end = "# CHANGELING CONFIG END"

let gitconfig_path = Fpath.(v ".git" / "config")

let gitattributes_path = Fpath.(v ".gitattributes")

let config =
  [%string
    {|
%{config_marker_start}
[merge "changeling"]
    name = changeling: changelog merge driver
    driver = changeling merge %A %B --out %A
%{config_marker_end}
|}]

let attribute changelog =
  let name = Fpath.to_string changelog in
  [%string
    {|
%{config_marker_start}
%{name} merge=changeling
%{config_marker_end}
|}]

let run : (module Model.S) -> Fpath.t -> (unit, _) Kwdcmd.cmd_result =
 fun (module Model) changelog ->
  let open Result.Infix in
  let* changelog_exists = Bos.OS.File.exists changelog in
  let* () =
    if not changelog_exists then
      Bos.OS.File.write changelog Model.(empty |> to_string)
    else
      Ok ()
  in
  let* git_dir_exists = Bos.OS.Dir.exists (Fpath.v ".git") in
  if not git_dir_exists then (
    Printf.eprintf
      "warning: not running from root of git repository, git will not be \
       configured\n";
    Ok ()
  ) else
    let* gitconfig_exists = Bos.OS.File.exists gitconfig_path in
    let* gitconfig =
      if gitconfig_exists then
        Bos.OS.File.read gitconfig_path
      else
        Ok ""
    in
    let* gitattributes_exists = Bos.OS.File.exists gitattributes_path in
    let* gitattributes =
      if gitattributes_exists then
        Bos.OS.File.read gitattributes_path
      else
        Ok ""
    in
    let* () =
      if not (String.mem ~sub:config_marker_start gitconfig) then
        Bos.OS.File.writef gitconfig_path "%s%s" gitconfig config
      else
        Ok ()
    in
    if not (String.mem ~sub:config_marker_start gitattributes) then
      Bos.OS.File.writef
        gitattributes_path
        "%s%s"
        gitattributes
        (attribute changelog)
    else
      Ok ()
