(** Document model of a keep a changelog style changelog file *)

type elem = Omd_representation.element
type md = Omd.t

(** A kind of change *)
module Change = struct
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

  module Map = Map.Make (T)
end

type version =
  { id : string  (** The version number (or "unreleased") *)
  ; date : string option  (** The date when the version was released *)
  ; summary : md  (** An optional summary of the version *)
  ; changes : md Change.Map.t  (** A map of change kinds to change lists *)
  }

type t =
  { title : elem  (** The title of the changelog (defaults to "Changelog")*)
  ; summary : md  (** Summary of the change log *)
  ; unreleased : version (** The not-yet released set of changes *)
  ; releases : version list (** All the versions that have been released *)
  }
