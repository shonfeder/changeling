(** Document model for a keep-a-changelog style changelog file *)

open Containers
open Fun.Infix

module Omd = struct
  module T = struct
    include Omd

    let compare : t -> t -> int =
     fun a b -> String.compare (Omd.to_text a) (Omd.to_text b)
  end

  module Elem = struct
    module T = struct
      type t = Omd_representation.element

      let compare : t -> t -> int =
       fun a b -> String.compare (Omd.to_markdown [ a ]) (Omd.to_markdown [ b ])
    end

    module Set = Set.Make (T)
  end

  include T
  module Set = Set.Make (T)
end

type elem = Omd_representation.element

type md = Omd.t

(** A kind of change *)
module Change = struct
  module T = struct
    (* TODO: make configurable *)
    type t =
      | Added
      | Changed
      | Deprecated
      | Removed
      | Fixed
      | Security
    [@@deriving eq, ord, show { with_path = false }, enum]
  end

  include T

  let all =
    List.(T.min -- T.max |> map (Option.get_exn_or "impossible" % T.of_enum))

  let all_allowed = all |> List.map show |> String.concat ", "

  let of_string = function
    | "Added"      -> Ok Added
    | "Changed"    -> Ok Changed
    | "Deprecated" -> Ok Deprecated
    | "Removed"    -> Ok Removed
    | "Fixed"      -> Ok Fixed
    | "Security"   -> Ok Security
    | invalid      ->
        Rresult.R.error_msg
          [%string
            "[invalid structure] invalid change '%{invalid}' expected one of \
             %{all_allowed}"]

  module Map = struct
    include Map.Make (T)

    type nonrec t = md t

    let to_md : t -> md =
      let change_to_md : T.t * md -> md =
       fun (change, changes) -> H3 [ Text (show change) ] :: changes
      in
      fun t ->
        (* Converting via to_seq ensures we get the items in the right order,
           converting directly `to_list` gives an undefined order. *)
        to_seq t |> Seq.to_list |> List.concat_map change_to_md

    let remove_empty t = filter (fun _ changes -> not (List.is_empty changes)) t

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
  end
end

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

  module Map = struct
    include Map.Make (T)

    type nonrec t = md t
  end
end

(** Get the id from a version header, if possible *)
let version_id : elem -> string option = function
  | H2 id -> Some (Omd.to_text id)
  | _     -> None

module Release = struct
  (* TODO: Actually parse out version data into a useful structure,
     this will be necessary for cleaner version extraction and for
     any automated link generation. *)
  type t =
    { version : elem
    ; summary : md  (** An optional summary of the version *)
    ; changes : Change.Map.t  (** A map of change kinds to change lists *)
    }

  let to_md { version; summary; changes } =
    (version :: summary) @ Change.Map.to_md changes

  let empty =
    let version : elem = H2 [ Text "Unreleased" ] in
    let changes =
      List.fold_left
        (fun m c -> Change.Map.add c [] m)
        Change.Map.empty
        Change.all
    in
    { version; summary = []; changes }

  let set_version v t =
    let version : elem = H2 [ Text v ] in
    (* Remove any change sections without content *)
    let changes = Change.Map.remove_empty t.changes in
    { t with version; changes }

  let is_for_version v t =
    match version_id t.version with
    | None    -> false
    | Some v' -> String.equal v v'

  let merge : t -> t -> (t, _) Result.t =
   fun t t' ->
    let v = Omd.to_markdown [ t.version ] |> String.trim in
    let v' = Omd.to_markdown [ t'.version ] |> String.trim in
    if not (String.equal v v') then
      Rresult.R.error_msgf "versions conflict: '%s' <> '%s'" v v'
    else
      let s = Omd.to_markdown t.summary |> String.trim in
      let s' = Omd.to_markdown t'.summary |> String.trim in
      if not (String.equal s s') then
        Rresult.R.error_msgf "release summaries conflict: '%s' <> '%s'" s s'
      else
        let changes =
          Change.Map.merge Change.Map.merge_changes t.changes t'.changes
        in
        Ok { t with changes }
end

type t =
  { title : elem  (** The title of the changelog (defaults to "Changelog")*)
  ; summary : md  (** Summary of the change log *)
  ; unreleased : Release.t  (** The not-yet released set of changes *)
  ; releases : Release.t list  (** All the versions that have been released *)
  }

(** TODO Replace manual parsing with monadic parsing *)
module Parser = struct
  type 'a t = Omd_representation.element list -> ('a, string) Result.t

  let return x = Ok x

  let bind f x =
    let open Result.Infix in
    let+ r, rest = x in
    (r, f rest)

  let map f x = Result.map (fun (r, rest) -> (r, f rest)) x

  let ( let* ) = bind

  let ( let+ ) x f = map f x
end

let parse_title (title : elem) =
  match title with
  | H1 _  -> Ok title
  | wrong ->
      let wrongmd = Omd.to_markdown [ wrong ] |> String.trim in
      Rresult.R.error_msg
        [%string
          "[invalid structure] expected '# Some title' but found '%{wrongmd}'"]

let is_blank_line : elem -> bool = function
  | NL
  | Paragraph [] ->
      true
  | _ -> false

let is_version_header : elem -> bool = function
  | H2 _ -> true (* TODO Validate content format *)
  | _    -> false

let is_change_header : elem -> bool = function
  | H3 _ -> true (* TODO Validate content format *)
  | _    -> false

let parse_summay md =
  Result.return @@ List.take_drop_while (not % is_version_header) md

type 'a parser = Omd_representation.element list -> ('a, Rresult.R.msg) Result.t

let unreleased_id = "Unreleased"

let is_unreleased_id s = String.equal s unreleased_id

let is_unreleased_version_header : elem -> bool =
 fun e ->
  match version_id e with
  | None   -> false
  | Some v -> is_unreleased_id v

let%test_unit "Unreleased header" =
  let is_valid s =
    s |> Omd.of_string |> List.hd |> is_unreleased_version_header
  in
  let is_invalid s = not (is_valid s) in
  ignore
    begin
      assert (is_invalid "# Unreleased");
      assert (is_invalid "### [Unreleased](foo/bar)");
      assert (is_invalid "## 1.0.1");
      assert (is_valid "## Unreleased");
      assert (is_valid "## [Unreleased](foo/bar/baz)");
      assert (is_valid {|## [Unreleased]

[Unreleased]: foo/bar/baz|})
    end

let is_change_section_header : elem -> bool = function
  | H3 [ Omd.Text change ] -> Change.of_string change |> Result.is_ok
  | _                      -> false

let%test_unit "Change section header" =
  let is_valid s = s |> Omd.of_string |> List.hd |> is_change_section_header in
  let is_invalid s = not (is_valid s) in
  ignore
    begin
      assert (is_valid "### Added");
      assert (is_valid "### Removed");
      assert (is_invalid "## Added");
      assert (is_invalid "### Not a change")
    end
(* let parse_change_section : ((Change.t * md) * md) parser = *)

let parse_changes md =
  let rec aux change_map : Change.Map.t parser = function
    | [] -> Ok change_map
    | H3 [ Text change_txt ] :: rest ->
        let open Result.Infix in
        let changes, rest =
          List.take_drop_while (not % is_change_section_header) rest
        in
        let* change = Change.of_string change_txt in
        let change_map = Change.Map.add change changes change_map in
        aux change_map rest
    | hd :: _ ->
        let wrong = Omd.to_markdown [ hd ] |> String.trim in
        Rresult.R.error_msg
          [%string
            "[invalid struture] expected change header but found '%{wrong}'"]
  in
  aux Change.Map.empty md

let parse_unreleased : (Release.t * md) parser = function
  | []              -> Rresult.R.error_msg "missing '## Unreleased' section"
  | version :: rest ->
      if not (is_unreleased_version_header version) then
        let wrong = Omd.to_markdown [ version ] |> String.trim in
        Rresult.R.error_msg
          [%string
            "[invalid structure] expected '## Unreleased' section but found \
             '%{wrong}'"]
      else
        let open Result.Infix in
        let summary, rest =
          List.take_drop_while (not % is_change_header) rest
        in
        let changes_md, rest =
          List.take_drop_while (not % is_version_header) rest
        in
        let* changes = parse_changes changes_md in
        let release = Release.{ version; summary; changes } in
        Ok (release, rest)

let rec parse_releases : Release.t list parser = function
  | []              -> Ok []
  | version :: rest ->
      if not (is_version_header version) then
        let wrong = Omd.to_markdown [ version ] |> String.trim in
        Rresult.R.error_msg
          [%string
            "[invalid structure] expected valid '## l.m.n' release section but \
             found '%{wrong}'"]
      else
        let open Result.Infix in
        let summary, rest =
          List.take_drop_while (not % is_change_header) rest
        in
        let changes_md, rest =
          List.take_drop_while (not % is_version_header) rest
        in
        let* changes = parse_changes changes_md in
        let release = Release.{ version; summary; changes } in
        let* releases = parse_releases rest in
        Ok (release :: releases)

let parse : string -> (t, _) Result.t =
 fun content ->
  Omd.of_string content |> List.filter (not % is_blank_line) |> function
  | []            -> Error (`Msg "[invalid structure] empty changelog")
  | title :: rest ->
      let open Result.Infix in
      let* title = parse_title title in
      let* summary, rest = parse_summay rest in
      let* unreleased, rest = parse_unreleased rest in
      let+ releases = parse_releases rest in
      { title; summary; unreleased; releases }

let to_string : t -> string =
 fun { title; summary; unreleased; releases } ->
  let unreleased = Release.to_md unreleased in
  let releases = List.concat_map Release.to_md releases in
  let md : md = (title :: NL :: summary) @ unreleased @ releases in
  Omd.to_markdown md

let release : version:string -> t -> t =
 fun ~version t ->
  { t with
    unreleased = Release.empty
  ; releases = Release.set_version version t.unreleased :: t.releases
  }

let get_version : version:string -> t -> Release.t option =
 fun ~version t ->
  List.find_map
    (fun r ->
      if Release.is_for_version version r then
        Some { r with changes = Change.Map.remove_empty r.changes }
      else
        None)
    (t.unreleased :: t.releases)

let merge : t -> t -> (t, _) Result.t =
 fun t t' ->
  let title = Omd.to_markdown [ t.title ] |> String.trim in
  let title' = Omd.to_markdown [ t'.title ] |> String.trim in
  if not (String.equal title title') then
    Rresult.R.error_msgf "titles conflict: '%s' <> '%s'" title title'
  else
    let summary = Omd.to_markdown t.summary |> String.trim in
    let summary' = Omd.to_markdown t'.summary |> String.trim in
    if not (String.equal summary summary') then
      Rresult.R.error_msgf "summaries conflict: '%s' <> '%s'" summary summary'
    else
      let open Result.Infix in
      let* unreleased = Release.merge t.unreleased t'.unreleased in
      let* releases =
        List.map2 Release.merge t.releases t'.releases |> Result.flatten_l
      in
      Ok { t with unreleased; releases }
