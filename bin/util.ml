open Kwdcmd

module Sexp = Sexplib.Sexp

(** Extending Fpath with some conversions *)
module Fpath = struct
  include Fpath

  let t_of_sexp = function
    | Sexp.Atom f -> Fpath.v f
    | sexp        ->
        let exn = Failure "paths must be represented by atoms" in
        raise (Sexplib0.Sexp.Of_sexp_error (exn, sexp))

  let sexp_of_t t = Sexp.Atom (Fpath.to_string t)

  let cmdline_conv = Arg.(conv (Fpath.of_string, Fpath.pp))
end
