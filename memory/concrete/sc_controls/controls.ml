(* Paired SC fixture groups. Each failure terminates the suite. *)
let () =
  (* Every fixture uses an empty tag environment; the native seam installs it once. *)
  Cerb_frontend.Tags.set_tagDefs (Pmap.empty Stdlib.compare);
  let group = if Array.length Sys.argv = 2 then Sys.argv.(1) else "all" in
  if not (List.mem group ["all"; "machine"; "adapter"]) then exit 2;
  if group = "all" || group = "machine" then (
    print_endline "sc_atomic_surface"; Run_sc_atomic_surface.run_tests ());
  if group = "all" || group = "machine" then (
    print_endline "sc_atomic_update"; Run_sc_atomic_update.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_global_binding"; Run_sc_global_binding.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_graph"; Run_sc_graph.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_hb"; Run_sc_hb.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_link_attribution"; Run_sc_link_attribution.run_tests ());
  if group = "all" || group = "machine" then (
    print_endline "sc_prototype"; Run_sc_prototype.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_reference_equality"; Run_sc_reference_equality.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_sequencing"; Run_sc_sequencing.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_spawn"; Run_sc_spawn.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_synchronization"; Run_sc_synchronization.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_value"; Run_sc_value.run_tests ());
  if group = "all" || group = "adapter" then (
    print_endline "sc_varargs"; Run_sc_varargs.run_tests ());
  if group = "all" || group = "machine" then (
    print_endline "fs_boundary"; Run_fs_boundary.run_tests ());
  print_endline "SC native controls passed"
