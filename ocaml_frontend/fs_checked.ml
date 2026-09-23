(* Checked interface to the actual SibylFS transition system.
   Derived from sibylfs/src/sibylfs.lem.
   Copyright (c) 2013, 2014, 2015, Tom Ridge, David Sheets, Thomas Tuerk,
   Andrea Giugliano (as part of the SibylFS project).
   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.
   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
   REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
   AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
   INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
   LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
   OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
   PERFORMANCE OF THIS SOFTWARE.

   Same call/tau/result/return and first/last selection as Sibylfs.run/run_last.
   A stopped transition has no successor: retain the last defined state and
   phase. A decoder fault instead retains the state AFTER OS_RETURN.
   Ordinary errors, named model specials, decoder/protocol failures, and port
   gaps are separate. No arbitrary host exception is converted to a model gap. *)
open Fs_spec.Fs_types
type phase = Call | Tau | Return
type fault =
 | Upstream_special of phase * monad_special_state * string
 | Upstream_decode of string * string
 | Upstream_leaf of phase * string
 | Missing_coverage of string
 | Protocol of string

let phase_text = function Call -> "call" | Tau -> "tau" | Return -> "return"
let fault_text = function
 | Upstream_special(_,kind,reason) ->
   "CerbFS upstream model special ("^Sexplib.Sexp.to_string(sexp_of_monad_special_state kind)^"): "^reason
 | Upstream_decode(decoder,value) -> "CerbFS upstream return conversion failure: "^decoder^" received "^value
 | Upstream_leaf(_,reason) -> "CerbFS upstream leaf failure: "^reason
 | Missing_coverage reason -> "CerbFS missing coverage: "^reason
 | Protocol reason -> "CerbFS protocol failure: "^reason

type selection = First | Last
let select selection values =
 match (match selection with First -> values | Last -> List.rev values) with
 | [] -> None | value::_ -> Some value

let transition selection phase st label next =
 (* This exact exception is the explicit Lem failure in list_array_write.
    Do not catch Overflow, Out_of_memory, arbitrary Failure, or host I/O. *)
 let states = try Either.Right (Dir_heap.Dir_heap_ops.dh_trans st label) with
  | Failure reason when reason="t.ml/write: offset + length greater than length of string" ->
    Either.Left (Upstream_leaf(phase,reason)) in
 match states with
 | Either.Left fault -> st,Either.Left fault
 | Either.Right states ->
   match select selection (Lem_support.list_from_finset states) with
   | None -> st,Either.Left(Protocol(phase_text phase^": empty transition set"))
   | Some(OS_special(kind,reason)) -> st,Either.Left(Upstream_special(phase,kind,reason))
   | Some(OS_normal after) -> next after

let run_with selection st decode command =
 let pid=Pid 1 in
 transition selection Call st (OS_CALL(pid,command)) (fun call ->
 transition selection Tau call OS_TAU (fun tau ->
  match select selection (Lem_support.list_from_finset(Dir_heap.Dir_heap_ops.dh_allowed_results_for_pid pid tau)) with
  | None -> tau,Either.Left(Protocol "results: empty result set")
  | Some result -> transition selection Return tau (OS_RETURN(pid,result)) (fun after ->
    match result with
    | Error error -> after,Either.Right(Either.Left error)
    | Value value -> match decode value with
      | Either.Left fault -> after,Either.Left fault
      | Either.Right value -> after,Either.Right(Either.Right value))))

let decode_failure decoder value =
 Either.Left(Upstream_decode(decoder,Sexplib.Sexp.to_string(sexp_of_ret_value value)))
let return_nat = function
 | RV_none -> Either.Right 0 | RV_num n -> Either.Right n | value -> decode_failure "return_nat" value
let return_bytes = function
 | RV_none -> Either.Right [] | RV_bytes bytes -> Either.Right(List_array.to_list bytes)
 | value -> decode_failure "return_bytes" value
let return_stat = function
 | RV_stats stat -> Either.Right stat | value -> decode_failure "return_stat" value
let run st decode command = run_with First st decode command
let run_last st decode command = run_with Last st decode command

(* Argument conversions are the original wrapper's. Overflow stays a host
   failure; the Lean port follows Lem's logical conversions under existing D4. *)
let fd_of_int = Sibylfs.fd_of_int
let file_perm_of_int = Sibylfs.file_perm_of_int
let uid_of_int = Sibylfs.uid_of_int
let gid_of_int = Sibylfs.gid_of_int
let run_mkdir st path mode = run st return_nat (OS_MKDIR(CS_Some path,file_perm_of_int mode))
let run_open st path flags mode =
 let mode=Some(file_perm_of_int(Option.value mode ~default:(Nat_big_num.of_int 511))) in
 run st return_nat (OS_OPEN(CS_Some path,Nat_big_num.to_int32 flags,mode))
let run_close st fd = run st return_nat (OS_CLOSE(fd_of_int fd))
let run_write st fd bytes count = run st return_nat
 (OS_WRITE(fd_of_int fd,List_array.of_list bytes,abs(Nat_big_num.to_int count)))
let run_read st fd count = run_last st return_bytes (OS_READ(fd_of_int fd,abs(Nat_big_num.to_int count)))
let run_pwrite st fd bytes count offset = run st return_nat
 (OS_PWRITE(fd_of_int fd,List_array.of_list bytes,abs(Nat_big_num.to_int count),Nat_big_num.to_int offset))
let run_pread st fd count offset = run_last st return_bytes
 (OS_PREAD(fd_of_int fd,abs(Nat_big_num.to_int count),Nat_big_num.to_int offset))
let run_rename st source target = run st return_nat (OS_RENAME(CS_Some source,CS_Some target))
let run_umask st mask = run st return_nat (OS_UMASK(file_perm_of_int mask))
let run_chmod st path mode = run st return_nat (OS_CHMOD(CS_Some path,file_perm_of_int mode))
let run_chdir st path = run st return_nat (OS_CHDIR(CS_Some path))
let run_chown st path uid gid = run st return_nat (OS_CHOWN(CS_Some path,uid_of_int uid,gid_of_int gid))
let run_link st source target = run st return_nat (OS_LINK(CS_Some source,CS_Some target))
let run_readlink st path = run st return_bytes (OS_READLINK(CS_Some path))
let run_symlink st target path = run st return_nat (OS_SYMLINK(CS_Some target,CS_Some path))
let run_rmdir st path = run st return_nat (OS_RMDIR(CS_Some path))
let run_truncate st path length = run st return_nat (OS_TRUNCATE(CS_Some path,Nat_big_num.to_int length))
let run_unlink st path = run st return_nat (OS_UNLINK(CS_Some path))
let run_lseek st fd offset whence = run st return_nat
 (OS_LSEEK(fd_of_int fd,Nat_big_num.to_int offset,Nat_big_num.to_int whence))
let run_stat st path = run st return_stat (OS_STAT(CS_Some path))
let run_lstat st path = run st return_stat (OS_LSTAT(CS_Some path))
let run_opendir st path = run st return_nat (OS_OPENDIR(CS_Some path))
let run_readdir st dir = run st return_bytes (OS_READDIR(DH(abs(Nat_big_num.to_int dir))))
let run_rewinddir st dir =
 let after,result=run st return_nat (OS_REWINDDIR(DH(abs(Nat_big_num.to_int dir)))) in
 (* Original run_rewinddir returns fst, ignoring ordinary errno. It does not
    ignore a wrapper/model fault. The Driver's completion remains void. *)
 match result with
 | Either.Left fault -> after,Either.Left fault
 | Either.Right _ -> after,Either.Right(Either.Right ())
let run_closedir st dir = run st return_nat (OS_CLOSEDIR(DH(abs(Nat_big_num.to_int dir))))
