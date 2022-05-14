open Sexplib.Std
open Containers

type t = { changes : string list option } [@@deriving sexp]

let empty = { changes = None }

let load ?(file = Fpath.v ".changeling") () =
  let open Result.Infix in
  let* file_exists = Bos.OS.File.exists file in
  if not file_exists then
    Ok empty
  else
    let fname = Fpath.to_string file in
    let+ s =
      try Sexplib.Sexp.load_sexp fname |> Result.return with
      | Sexplib.Sexp.Parse_error _
      | Failure _ ->
          Rresult.R.error_msgf "invalid s-expression in config file %s" fname
    in
    t_of_sexp s
