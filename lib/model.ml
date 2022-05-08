(* Document model of a keep a changelog style changelog file *)

type elem = Omd_representation.element
type md = Omd.t

module Change = struct
  type t =
    | Breaking_changes
    | Bug_fixes
    | Deprecations
    | Documentation
    | Features

  (* TODO: make configurable *)
  let to_string = function
    | Breaking_changes -> "Breaking changes"
    | Bug_fixes        -> "Bug fixes"
    | Deprecations     -> "Deprecations"
    | Documentation    -> "Documentation"
    | Features         -> "Features"
end

type section =
  { kind : Change.t
  ; changes : md
  }

type version =
  { id : string
  ; summary : md
  ; date : string option
  ; sections : section list
  }

type t =
  { title : elem
  ; summary : md
  ; unreleased : version
  ; releases : version list
  }
