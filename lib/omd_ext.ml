(** Extension to the Omd library *)

open Containers

module Elem = struct
  module T = struct
    type t = Omd_representation.element

    let compare : t -> t -> int =
      fun a b -> String.compare (Omd.to_markdown [ a ]) (Omd.to_markdown [ b ])
  end

  module Set = Set.Make (T)
end

module T = struct
  include Omd

  let compare : t -> t -> int =
    fun a b -> String.compare (Omd.to_text a) (Omd.to_text b)
end

module Set = Set.Make (T)
include T
