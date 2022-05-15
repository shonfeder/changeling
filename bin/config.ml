open Sexplib.Std
open Containers
module Sexp = Sexplib.Sexp
open Util

module Default = struct
  (** The default change kinds, following the pattern in keep a changelog *)
  let changes =
    [ "Added"; "Changed"; "Deprecated"; "Removed"; "Fixed"; "Security" ]

  let changelog = Fpath.v "CHANGES.md"
end

type t =
  { changes : string list [@default Default.changes]
  ; changelog : Fpath.t [@default Default.changelog]
  }
[@@deriving sexp]
(** All application configurations that can be read from a file *)

let default = t_of_sexp (Sexp.List [])

let load ?file () =
  let open Result.Infix in
  let source, file =
    match file with
    | None   -> (`Default, Fpath.v ".changeling")
    | Some f -> (`Configured, f)
  in
  let* file_exists = Bos.OS.File.exists file in
  let fname = Fpath.to_string file in
  match (source, file_exists) with
  | `Default, false    -> Ok default
  | `Configured, false ->
      Rresult.R.error_msgf "configuration file %a cannot be found" Fpath.pp file
  | _otherwise, true   ->
  match Sexplib.Sexp.load_sexp fname |> t_of_sexp with
  | (exception Failure _)
  | (exception Sexp.Parse_error _) ->
      Rresult.R.error_msgf "invalid s-expression in configuration file %s" fname
  | exception Sexplib0.Sexp.Of_sexp_error _ ->
      (* TODO Print example of valid config name? *)
      Rresult.R.error_msgf "invalid configuration in file %s" fname
  | t -> Ok t

type options =
  { model : (module Changeling.Model.S)
  ; changelog : Fpath.t
  }

open Kwdcmd
open Util

let options =
  let+ config_file =
    Optional.value
      "CONFIG_FILE"
      ~doc:
        "Location of the configuration file to read (defaults to .changling in \
         the currently working directory)"
      ~docs:Manpage.s_common_options
      ~flags:[ "config"; "C" ]
      ~default:None
      ~conv:Arg.(some Fpath.cmdline_conv)
      ()
  and+ changelog_file =
    Optional.value
      "CHANGELOG_FILE"
      ~doc:
        "The changelog file to operate on (defaults to CHANGES.md), overrides \
         the value set in the config file"
      ~docs:Manpage.s_common_options
      ~flags:[ "changelog"; "c" ]
      ~default:None
      ~conv:Arg.(some Fpath.cmdline_conv)
      ()
  in
  let open Containers.Result.Infix in
  let open Changeling in
  let+ { changes; changelog } = load ?file:config_file () in
  let (module C) = Change.make changes in
  (* Try to use the CLI supplied changelog file, and fall back to configured changelog file *)
  let changelog = Option.get_or ~default:changelog changelog_file in
  let model = (module Model.Make (C) : Model.S) in
  { model; changelog }
