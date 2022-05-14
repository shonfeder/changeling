open Containers
module Omd = Omd_ext

(** TODO *)
module ApalacheChange = struct
  module T = struct
    (* TODO: make configurable *)
    type t =
      | Breaking_changes
      | Bug_fixes
      | Deprecations
      | Features
      | Documentation
    [@@deriving eq, ord]
  end

  include T

  let to_string = function
    | Breaking_changes -> "Breaking changes"
    | Features         -> "Features"
    | Bug_fixes        -> "Bug fixes"
    | Deprecations     -> "Deprecations"
    | Documentation    -> "Documentation"
end

module type S = sig
  type t = private string

  val of_string : string -> (t, Rresult.R.msg) Result.t

  val to_string : t -> string

  val kinds : t list

  module Map : sig
    type key = t

    type t

    val empty : t

    val add : key -> Omd.t -> t -> t

    val to_md : t -> Omd.t

    val merge : t -> t -> t

    val remove_empty : t -> t
  end
end

module Make (C : sig
  val kinds : string list
end) : S = struct
  include String

  let kinds = C.kinds

  module T = struct
    type t = string

    let compare a b =
      let idx_a =
        List.find_idx (String.equal a) kinds
        |> Option.get_exn_or "impossible"
        |> fst
      in
      let idx_b =
        List.find_idx (String.equal b) kinds
        |> Option.get_exn_or "impossible"
        |> fst
      in
      Int.compare idx_a idx_b
  end
  include T

  let all_allowed = String.concat ", " C.kinds

  let of_string s =
    if List.mem s C.kinds then
      Ok s
    else
      Rresult.R.error_msg
        [%string
          "[invalid structure] invalid change '%{s}' expected one of \
           %{all_allowed}"]

  let to_string x = x

  module Map = struct
    module M = Map.Make (T)

    type key = t

    type nonrec t = Omd.t M.t

    let empty, add = M.(empty, add)

    let to_md : t -> Omd.t =
      let change_to_md : string * Omd.t -> Omd.t =
       fun (change, changes) -> H3 [ Text change ] :: changes
      in
      fun t ->
        (* Converting via to_seq ensures we get the items in the right order,
           converting directly `to_list` gives an undefined order. *)
        M.to_seq t |> Seq.to_list |> List.concat_map change_to_md

    let remove_empty t =
      M.filter (fun _ changes -> not (List.is_empty changes)) t

    (* TODO This should actually walk the AST and do a clevar merge on mergable structures *)
    let merge_changes _ a b =
      match (a, b) with
      | None, c
      | c, None ->
          c
      | Some a, Some b ->
      match (a, b) with
      | [ Omd.Ul a_items ], [ Ul b_items ] ->
          Some
            [ Omd.Ul
                Omd.Set.(union (of_list a_items) (of_list b_items) |> to_list)
            ]
      | a, b -> Some Omd.Elem.Set.(union (of_list a) (of_list b) |> to_list)

    let merge a b = M.merge merge_changes a b
  end
end

let make kinds : (module S) =
  (module Make (struct let kinds = kinds end))
