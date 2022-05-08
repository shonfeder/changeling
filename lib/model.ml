(** Document model for a keep-a-changelog style changelog file *)

open Containers
open Fun.Infix

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
    [@@deriving eq, ord, show, enum]
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
        Error
          [%string "invalid change '%{invalid}' expected one of %{all_allowed}"]

  module Map = struct
    include Map.Make (T)

    type nonrec t = md t
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

type version =
  { id : string  (** The version number (or "unreleased") *)
  ; date : string option  (** The date when the version was released *)
  ; summary : md  (** An optional summary of the version *)
  ; changes : Change.Map.t  (** A map of change kinds to change lists *)
  }

type t =
  { title : elem  (** The title of the changelog (defaults to "Changelog")*)
  ; summary : md  (** Summary of the change log *)
  ; unreleased : version  (** The not-yet released set of changes *)
  ; releases : version list  (** All the versions that have been released *)
  }

module Parser = struct
  type 'a t = Omd_representation.element list -> ('a, string) Result.t

  let return x = Ok x
  let bind f x =
    let open Result.Infix in
    let+ (r, rest) = x in
    (r, f rest)

  let map f x = Result.map (fun (r, rest) -> (r, f rest) ) x

  let (let*) = bind
  let (let+) x f = map f x
end

let parse_title (title : elem) =
  match title with
  | H1 _  -> Ok title
  | wrong ->
      let wrongmd = Omd.to_markdown [ wrong ] |> String.trim in
      Error [%string "expected '# Some title' but found '%{wrongmd}'"]

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

type 'a parser = Omd_representation.element list -> ('a, string) Result.t

let unreleased_id = "Unreleased"

let is_unreleased_id s = String.equal s unreleased_id

let is_unreleased_version_header : elem -> bool = function
  | H2 [ Omd.Ref (_, id, ref_id, _) ] ->
      is_unreleased_id id && is_unreleased_id ref_id
  | H2 [ Omd.Url (_, [ Omd.Text id ], _) ]
  | H2 [ Omd.Text id ] ->
      is_unreleased_id id
  | _ -> false

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
        Error [%string "expected change header but found '%{wrong}'"]
  in
  aux Change.Map.empty md

let parse_unreleased : (version * md) parser = function
  | []         -> Error "missing '## Unreleased' section"
  | hd :: rest ->
      if not (is_unreleased_version_header hd) then
        let wrong = Omd.to_markdown [ hd ] |> String.trim in
        Error [%string "expected '## Unreleased' section but found '%{wrong}'"]
      else
        let open Result.Infix in
        let summary, rest =
          List.take_drop_while (not % is_change_header) rest
        in
        let changes_md, rest =
          List.take_drop_while (not % is_version_header) rest
        in
        let* changes = parse_changes changes_md in
        let version = { id = unreleased_id; date = None; summary; changes } in
        Ok (version, rest)

let parse_releases _ = raise (Failure "TODO releases")

let parse : string -> (t, string) Result.t =
 fun content ->
  Omd.of_string content |> List.filter (not % is_blank_line) |> function
  | []            -> Error "empty changelog"
  | title :: rest ->
      let open Result.Infix in
      let* title = parse_title title in
      let* summary, rest = parse_summay rest in
      let* unreleased, rest = parse_unreleased rest in
      let+ releases = parse_releases rest in
      { title; summary; unreleased; releases }
