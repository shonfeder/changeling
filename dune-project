(lang dune 2.9)
(cram enable)
(generate_opam_files true)

(name changeling)
(license MIT)
(authors "Shon Feder")
(maintainers "Shon Feder")
(source (github shonfeder/changeling))

(package
 (name changeling)
 (synopsis "Short description")
 (description "Longer description")
 (depends
  (dune (> 2.9))
   ocaml

   ; Libraies
   kwdcmd                       ; pinned
  (omd (= 1.3.1))
  (bos (>= 0.2.1))
  (containers (>= 3.7))
  (sexplib (>= v0.15.0))

  ; Preprocessing
  (ppx_string (>= v0.15.0))
  (ppx_sexp_conv (>= v0.15.0))

  ;  Testing
  (ppx_inline_test (>= v0.15.0))
  (alcotest :with-test)
  (qcheck :with-test)
  (qcheck-alcotest :with-test)
))
