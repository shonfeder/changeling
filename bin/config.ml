open Sexplib.Std
open Containers
module Sexp = Sexplib.Sexp

type t = { changes : string list [@default []] } [@@deriving sexp]
(** All application configurations that can be read from a file *)

(** The default change kinds, following the pattern in keep a changelog *)
let changes =
  [ "Added"; "Changed"; "Deprecated"; "Removed"; "Fixed"; "Security" ]

let default = { changes }

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
