open Cerb_frontend
open Core
let set_uid_globs x = x
let set_uid_fun _ x = x
let set_uid file1 =
 ({
  main=    (file1.main);
  calling_convention= (file1.calling_convention);
  tagDefs= (file1.tagDefs);
  enumDefs= (file1.enumDefs); (* program-data parameters E-A (2026-09-20): preserved, never emptied *)
  stdlib=  (file1.stdlib);
  impl=    (file1.impl);
  globs=   List.map set_uid_globs file1.globs;
  funs=    (Pmap.mapi set_uid_fun file1.funs);
  funinfo= (file1.funinfo);
  extern=  file1.extern;
  loop_attributes0= file1.loop_attributes0;
  visible_objects_env = file1.visible_objects_env;
 })

