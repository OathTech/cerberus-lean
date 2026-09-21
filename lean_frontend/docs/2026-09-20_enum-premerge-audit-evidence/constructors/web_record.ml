open Cerb_frontend
open Core
let set_globs x = x
let set_fun _ x = x
let audit (file : unit Core.file) =
  { main=    file.main;
    calling_convention= file.calling_convention;
    tagDefs= file.tagDefs;
    stdlib=  file.stdlib;
    impl=    file.impl;
    globs=   List.map set_globs file.globs;
    funs=    Pmap.mapi set_fun file.funs;
    extern=  file.extern;
    funinfo= file.funinfo;
    loop_attributes0= file.loop_attributes0;
    visible_objects_env= file.visible_objects_env;
  }
