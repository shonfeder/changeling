open Kwdcmd

let main () =
  Exec.commands
    ~name:"changeling"
    ~version:"0.0.1"
    ~doc:"Harmonize changelogs"
    []


let () = main ()
