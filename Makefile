# Checking for required tools.
# Lean-only targets don't require dune.
LEAN_TARGETS := lean-prelude-src lean-build clean-lean rebuild-lem
ifneq ($(MAKECMDGOALS),)
ifeq ($(filter-out $(LEAN_TARGETS),$(MAKECMDGOALS)),)
_SKIP_DUNE_CHECK := 1
endif
endif
ifndef _SKIP_DUNE_CHECK
ifeq (,$(shell command -v dune 2> /dev/null))
$(error "Compilation requires [dune].")
endif
endif
ifeq (,$(shell command -v lem 2> /dev/null))
$(error "Compilation requires [lem].")
endif

# GNU vs BSD
ifeq (GNU,$(shell sed --version 2>&1 > /dev/null && echo GNU))
SEDI = sed -i
else
SEDI = sed -i ''
endif

PROFILE = dev
DUNEFLAGS = --profile=$(PROFILE)
ifdef PROFILING
    DUNEFLAGS += --workspace=dune-workspace.profiling
endif

# Trick to avoid printing the commands.
# To enable the printing of commands, use [make Q= ...],
Q = @

.PHONY: normal
normal: cerberus

.PHONY: all
all: cerberus cerberus-bmc cerberus-web #rustic

.PHONY: full-build
full-build: prelude-src
	@echo "[DUNE] full build"
	$(Q)dune build $(DUNEFLAGS)

.PHONY: util
util:
	@echo "[DUNE] library [$@]"
	$(Q)dune build $(DUNEFLAGS) _build/default/$@/$@.cma _build/default/$@/$@.cmxa
	ifdef PROFILING
		$(Q)dune build $(DUNEFLAGS) _build/profiling/$@/$@.cma _build/profiling/$@/$@.cmxa
		$(Q)dune build $(DUNEFLAGS) _build/profiling-auto/$@/$@.cma _build/profiling-auto/$@/$@.cmxa
	endif

.PHONY: sibylfs
sibylfs: sibylfs-src
	@echo "[DUNE] library [$@]"
	$(Q)dune build $(DUNEFLAGS) _build/default/$@/$@.cma _build/default/$@/$@.cmxa
	ifdef PROFILING
		$(Q)dune build $(DUNEFLAGS) _build/profiling/$@/$@.cma _build/profiling/$@/$@.cmxa
		$(Q)dune build $(DUNEFLAGS) _build/profiling/$@/$@.cma _build/profiling-auto/$@/$@.cmxa
	endif

.PHONY: cerberus
cerberus: prelude-src
	@echo "[DUNE] cerberus"
	$(Q)dune build $(DUNEFLAGS) cerberus-lib.install cerberus.install

.PHONY: test
test: prelude-src
	@echo "testing"
	dune exec coq/coqcaptest.exe

.PHONY: cerberus-bmc bmc
bmc: cerberus-bmc
cerberus-bmc: prelude-src
	@echo "[DUNE] cerberus-bmc"
	$(Q)dune build $(DUNEFLAGS) cerberus-lib.install cerberus-bmc.install

# .PHONY: rustic
# rustic: prelude-src
# 	@echo "[DUNE] $@"
# 	$(Q)dune build $(DUNEFLAGS) cerberus.install rustic.install

cheri: prelude-src
	@echo "[DUNE] cerberus-cheri"
	$(Q)dune build $(DUNEFLAGS) cerberus-lib.install cerberus-cheri.install

# combined goal to build both cerberus and cheri together as single dune run.
# building them separately form makefile causes them to run two confilcting
# dune builds in parallel
.PHONY: cerberus-with-cheri
cerberus-with-cheri: prelude-src
	@echo "[DUNE] cerberus-with-cheri"
	$(Q)dune build $(DUNEFLAGS) cerberus-lib.install cerberus.install cerberus-cheri.install

# .PHONY: cerberus-ocaml ocaml
# ocaml: cerberus-ocaml
# cerberus-ocaml: prelude-src
# 	@echo "[DUNE] $@"
# 	$(Q)dune build _build/default/backend/ocaml/driver/main.exe
# 	FIXME does not compile
# 	FIXME should generate rt-ocaml as a library
# 	@echo $(BOLD)INSTALLING Ocaml Runtime in ./_lib$(RESET)
# 	@mkdir -p _lib/rt-ocaml
# 	@cp backend/ocaml/runtime/META _lib/rt-ocaml
# 	@cp backend/ocaml/runtime/_build/rt_ocaml.a \
# 		   backend/ocaml/runtime/_build/rt_ocaml.cma \
# 			 backend/ocaml/runtime/_build/rt_ocaml.cmxa _lib/rt-ocaml
# 	@cp backend/ocaml/runtime/_build/*.cmi _lib/rt-ocaml
# 	@cp backend/ocaml/runtime/_build/*.cmx _lib/rt-ocaml
# 	@cp backend/ocaml/runtime/_build/src/*.cmi _lib/rt-ocaml
# 	@cp backend/ocaml/runtime/_build/src/*.cmx _lib/rt-ocaml

.PHONY: cerberus-web web web-deployment
web-deployment:
	@echo "Setting up Webapp deployment directory"
	$(Q)mkdir -p public/_deployment/
	$(Q)mkdir -p public/_deployment/tmp/
	$(Q)mkdir -p public/_deployment/logs/
	$(Q) sed 's?#SRC_ROOT#?'$(shell pwd)'?' tools/config.json > public/_deployment/config.json

web: cerberus-web
cerberus-web: prelude-src web-deployment
	@echo "[DUNE] web"
	$(Q)dune build $(DUNEFLAGS) cerberus-lib.install cerberus-web.install
	$(Q) rm -f webcerb.concrete webcerb.symbolic webcerb.vip cerberus-webserver
	$(Q)cp -L _build/default/backend/web/instance.exe webcerb.concrete
	$(Q)cp -L _build/default/backend/web/instance_symbolic.exe webcerb.symbolic
	$(Q)cp -L _build/default/backend/web/instance_vip.exe webcerb.vip
	$(Q)cp -L _build/default/backend/web/web.exe cerberus-webserver

.PHONY: ui
ui:
	make -C public

#### LEM sources for the frontend
LEM_RENAMED = global.lem loc.lem debug.lem decode.lem

LEM_PRELUDE       = utils.lem annot.lem bimap.lem \
                    dlist.lem enum.lem state.lem symbol.lem \
                    exception.lem product.lem float.lem any.lem
LEM_CABS          = cabs.lem undefined.lem constraint.lem integerType.lem ctype.lem
LEM_AIL           = typingError.lem errorMonad.lem ailSyntax.lem genTypes.lem
LEM_CTYPE_AUX     = ctype_aux.lem
LEM_CORE          = core.lem errors.lem core_aux.lem core_linking.lem
LEM_CORE_TYPING   = core_typing.lem core_typing_aux.lem core_typing_effect.lem
LEM_UTILS         = boot.lem exception_undefined.lem multiset.lem \
                    state_exception.lem state_exception_undefined.lem \
                    std.lem monadic_parsing.lem fs.lem trace_event.lem \
										cerb_attributes.lem
LEM_AIL_TYPING    = range.lem integerImpl.lem ailTypesAux.lem \
                    ailSyntaxAux.lem ailWf.lem ailTyping.lem genTypesAux.lem \
                    genTyping.lem
LEM_CABS_TO_AIL   = cabs_to_ail_aux.lem scope_table.lem \
                    desugaring_init.lem cabs_to_ail_effect.lem cabs_to_ail.lem mini_pipeline.lem
LEM_CORE_TO_CORE  = core_sequentialise.lem core_indet.lem core_rewrite.lem \
                    core_unstruct.lem
LEM_CORE_DYNAMICS = core_run_aux.lem core_eval.lem core_run.lem core_reduction.lem core_reduction_aux.lem driver.lem
LEM_ELABORATION   = translation_effect.lem translation_aux.lem translation.lem 
LEM_DEFACTO       = mem_common.lem defacto_memory_types.lem \
                    defacto_memory_aux.lem defacto_memory.lem mem.lem \
                    mem_aux.lem
LEM_CONC_INTERF   = cmm_aux.lem
LEM_CONC          = cmm_csem.lem cmm_op.lem linux.lem

LEM_CN            = cn.lem cn_desugaring.lem

LEM_SRC_AUX       = $(LEM_PRELUDE) \
                    $(LEM_CN) \
                    $(LEM_CABS) \
                    $(addprefix ail/, $(LEM_AIL)) \
                    $(LEM_CTYPE_AUX) \
                    builtins.lem formatted.lem pp.lem implementation.lem \
                    $(LEM_DEFACTO) \
                    $(LEM_UTILS) \
                    nondeterminism.lem \
                    $(LEM_CONC_INTERF) \
                    $(LEM_CORE) \
                    $(LEM_CORE_TYPING) \
                    $(addprefix ail/, $(LEM_AIL_TYPING)) \
                    $(LEM_CABS_TO_AIL) \
                    $(LEM_CORE_TO_CORE) \
                    $(LEM_CORE_DYNAMICS) \
                    $(LEM_ELABORATION)

LEM_SRC_RENAMED = $(addprefix frontend/model/, $(LEM_RENAMED))

LEM_SRC_NOT_RENAMED = $(addprefix frontend/model/, $(LEM_SRC_AUX)) \
					$(addprefix frontend/concurrency/, $(LEM_CONC))

LEM_SRC = $(LEM_SRC_RENAMED) \
					$(LEM_SRC_NOT_RENAMED)

# Lean generation list (effect-retirement C1, charter section 3.4 e):
# the Core_unstruct pair is Lean-dead (imported by nothing in the Lean
# build; its two Symbol.fresh sites sit inside foldl/map lambdas that
# would trip the supply transform's G-lambda guard). It stays in
# LEM_SRC for the OCaml target (upstream's sequentialisation pass,
# untouched).
LEM_SRC_LEAN = $(filter-out frontend/model/core_unstruct.lem,$(LEM_SRC))
####

PRELUDE_SRC_DIR = ocaml_frontend/generated
OCAML_SRC = $(addprefix $(PRELUDE_SRC_DIR)/, $(addsuffix .ml, $(notdir $(basename $(LEM_SRC_NOT_RENAMED))))) \
						$(addprefix $(PRELUDE_SRC_DIR)/lem_, $(addsuffix .ml, $(notdir $(basename $(LEM_RENAMED)))))

# Lem-sync content stamp (hotfix arc/hotfix-libc-floor, 2026-08-22):
# written ONLY by the generation recipe below, immediately after lem+sed,
# and verified by tools/check_lem_sync.sh --check (wired into the dune
# graph via ocaml_frontend/dune `lem_sync_checked` and into
# scripts/test_unit.sh). Guards against dune-building a STALE generated
# tree (dune cannot see the .lem sources; make's own dependency is
# mtime-based and no-ops on stale content after worktree priming).
# Record: lean_frontend/docs/2026-08-22_arc13-hotfix-libc-floor.md.
PRELUDE_SYNC_STAMP = ocaml_frontend/lem_sync.sha256

# All targets generated at once thanks to [&:].
$(OCAML_SRC) $(PRELUDE_SYNC_STAMP)&: $(LEM_SRC)
	@echo "[MKDIR] $(PRELUDE_SRC_DIR)"
	$(Q)mkdir -p $(PRELUDE_SRC_DIR)
	@echo "[LEM] generating files in [$(PRELUDE_SRC_DIR)] (log in [ocaml_frontend/lem.log])"
	$(Q)lem -wl ign -wl_rename warn -wl_pat_red err -wl_pat_exh warn \
    -outdir $(PRELUDE_SRC_DIR) -cerberus_pp -ocaml \
    $(LEM_SRC) 2> ocaml_frontend/lem.log || (>&2 cat ocaml_frontend/lem.log; exit 1)
	@echo "[SED] patching things up in [$(PRELUDE_SRC_DIR)]"
	$(Q)$(SEDI) -e "s/open Operators//" $(PRELUDE_SRC_DIR)/core_run.ml
	$(Q)$(SEDI) -e "s/open Operators//" $(PRELUDE_SRC_DIR)/driver.ml
	$(Q)$(SEDI) -e "s/Lem_debug.DB_/Cerb_debug.DB_/g" $(OCAML_SRC)
	$(Q)$(SEDI) -e "1 s/.*/&[@@@warning \"-8\"]/" $(PRELUDE_SRC_DIR)/cmm_csem.ml
	$(Q)$(SEDI) -e "1 s/.*/&[@@@warning \"-8\"]/" $(PRELUDE_SRC_DIR)/cmm_op.ml
	@echo "[STAMP] recording lem-sync content stamp"
	$(Q)bash tools/check_lem_sync.sh --record

# Elaboration PP stuff
elab_pp:
	@echo "[MKDIR] $(PRELUDE_SRC_DIR)"
	$(Q)mkdir -p generated_tex
	$(Q)lem -wl ign -wl_rename warn -wl_pat_red err -wl_pat_exh warn \
	-outdir generated_tex -cerberus_pp -tex \
	$(addprefix -i ,$(filter-out frontend/model/translation.lem,$(LEM_SRC))) frontend/model/translation.lem
	cd generated_tex; lualatex Translation.tex


#### LEM sources for sibylfs
SIBYLFS_LEM = dir_heap.lem fs_prelude.lem fs_spec.lem list_array.lem \
              sibylfs.lem
SIBYLFS_ML  = abstract_string.ml fs_dict_wrappers.ml fs_interface.ml \
              fs_dump.ml fs_printer.ml lem_support.ml
SIBYLFS_MLI = abstract_string.mli fs_dict_wrappers.mli fs_interface.mli \
              lem_support.mli

SIBYLFS_LEM_ML  = $(addsuffix .ml, $(basename $(SIBYLFS_LEM)))

SIBYLFS_LEM_SRC = $(addprefix sibylfs/src/, $(SIBYLFS_LEM))
SIBYLFS_ML_SRC  = $(addprefix sibylfs/src/, $(SIBYLFS_ML))
SIBYLFS_MLI_SRC = $(addprefix sibylfs/src/, $(SIBYLFS_MLI))

SIBYLFS_LEM_TRG = $(addprefix sibylfs/generated/, $(SIBYLFS_LEM_ML))
SIBYLFS_ML_TRG  = $(addprefix sibylfs/generated/, $(SIBYLFS_ML))
SIBYLFS_MLI_TRG = $(addprefix sibylfs/generated/, $(SIBYLFS_MLI))

SIBYLFS_SRC = $(SIBYLFS_LEM_SRC) $(SIBYLFS_ML_SRC) $(SIBYLFS_MLI_SRC)
SIBYLFS_TRG = $(SIBYLFS_LEM_TRG) $(SIBYLFS_ML_TRG) $(SIBYLFS_MLI_TRG)

SIBYLFS_SED = sibylfs/patch_all_ml.sed sibylfs/patch/dir_heap.sed \
              sibylfs/patch/fs_prelude.sed sibylfs/patch/fs_spec.sed
####

SIBYLFS_SRC_DIR = sibylfs/generated

# All targets generated at once thanks to [&:].
$(SIBYLFS_TRG)&: $(SIBYLFS_SRC) $(SIBYLFS_SED)
	@echo "[MKDIR] $(SIBYLFS_SRC_DIR)"
	$(Q)mkdir -p $(SIBYLFS_SRC_DIR)
	@echo "[LEM] generating files in [$(SIBYLFS_SRC_DIR)] (log in [sibylfs/lem.log])"
	$(Q)lem -wl_unused_vars ign -wl_rename err -wl_comp_message ign \
	  -wl_pat_exh ign -outdir $(SIBYLFS_SRC_DIR) -ocaml \
    $(SIBYLFS_LEM_SRC) 2> sibylfs/lem.log
	@echo "[CP] $(SIBYLFS_MLI_TRG)"
	$(Q)cp $(SIBYLFS_MLI_SRC) $(SIBYLFS_SRC_DIR)
	@echo "[CP] $(SIBYLFS_ML_TRG)"
	$(Q)cp $(SIBYLFS_ML_SRC) $(SIBYLFS_SRC_DIR)
	@echo "[SED] patching things up in [$(SIBYLFS_SRC_DIR)]"
	$(Q)$(SEDI) -f sibylfs/patch/dir_heap.sed   sibylfs/generated/dir_heap.ml
	$(Q)$(SEDI) -f sibylfs/patch/fs_prelude.sed sibylfs/generated/fs_prelude.ml
	$(Q)$(SEDI) -f sibylfs/patch/fs_spec.sed    sibylfs/generated/fs_spec.ml
	$(Q)$(SEDI) -f sibylfs/patch_all_ml.sed $(SIBYLFS_LEM_TRG) $(SIBYLFS_ML_TRG)

.PHONY: prelude-src
prelude-src: $(OCAML_SRC) sibylfs-src

.PHONY: sibylfs-src
sibylfs-src: $(SIBYLFS_TRG)

.PHONY: clean-prelude-src
clean-prelude-src:
	$(Q)rm -rf $(PRELUDE_SRC_DIR)
	$(Q)rm -f ocaml_frontend/lem.log $(PRELUDE_SYNC_STAMP)

.PHONY: clean-sibylfs-src
clean-sibylfs-src:
	$(Q)rm -rf $(SIBYLFS_SRC_DIR)
	$(Q)rm -f sibylfs/lem.log

#### Lean frontend (generated from the same LEM_SRC as the OCaml frontend)
LEAN_SRC_DIR = lean_frontend/generated

# Hand-written Lean files copied into generated/ so they're importable
# by the generated code (which references them via declare lean target_rep).
# THE LIST LIVES IN lean_frontend/handwritten_copy.manifest (hotfix
# fix/freshness-copy-gap, 2026-09-02): one authority shared with
# tools/check_handwritten_sync.sh, which byte-pins every copy against its
# source (via check_driver_fresh --record-lean/--check, common.sh
# build_lean, test_unit.sh). Entries are the lines starting with a letter
# (comment lines start with '#'). Fail-closed: a missing or empty manifest
# is a parse-time error, never an empty copy.
# Main.lean is in the list since arc-4 S5f: it was previously copied only
# by hand, and a stale generated/Main.lean silently dropped the S1r floor
# probe from the built binary (audit-2 G2).
LEAN_HANDWRITTEN_MANIFEST = lean_frontend/handwritten_copy.manifest
LEAN_HANDWRITTEN := $(strip $(shell sed -n '/^[A-Za-z]/p' $(LEAN_HANDWRITTEN_MANIFEST) 2>/dev/null))
ifeq (,$(LEAN_HANDWRITTEN))
$(error "lean_frontend: hand-written copy manifest $(LEAN_HANDWRITTEN_MANIFEST) missing or empty (fail-closed; nothing would be copied into generated/)")
endif

# Reinstall lem via opam.  Lem is opam-pinned in the LOCAL switch to the
# container worktree deps/lem-pinned (lem-lean fork, branch cerberus-pin):
#   opam pin list --switch=.  ->  git+file:///.../deps/lem-pinned#cerberus-pin
# To move the pin, FIRST move that worktree (git -C ../deps/lem-pinned
# reset --hard <lem-lean commit>), then run this target: `opam upgrade`
# rebuilds and installs if the pinned source changed. Path form because the
# switch is local; --no-depexts because system-package detection fails in
# the sandbox (container CLAUDE.md, "opam in the sandbox"). Afterwards
# regenerate both trees (prelude-src, lean-prelude-src): the lem-sync
# stamps hash sources + outputs, not the lem version.
.PHONY: rebuild-lem
rebuild-lem:
	@echo "[LEM] reinstalling lem from the pinned local source (deps/lem-pinned#cerberus-pin)"
	$(Q)opam upgrade --switch=. --no-depexts -y lem
	@echo "[LEM] installed $$(lem -v 2>&1)"

.PHONY: lean-prelude-src
lean-prelude-src: $(LEM_SRC)
	@echo "[MKDIR] $(LEAN_SRC_DIR)"
	$(Q)mkdir -p $(LEAN_SRC_DIR)
	@# effect-retirement C1: the Core_unstruct pair leaves the Lean build
	@# (LEM_SRC_LEAN); stale generated copies are removed fail-closed so a
	@# lingering artifact cannot shadow the build-list drop.
	$(Q)rm -f $(LEAN_SRC_DIR)/Core_unstruct.lean $(LEAN_SRC_DIR)/Core_unstruct_auxiliary.lean
	@echo "[LEM] generating Lean files in [$(LEAN_SRC_DIR)] (log in [lean_frontend/lem.log])"
	$(Q)lem -wl ign -wl_rename warn -wl_pat_red err -wl_pat_exh warn \
    -outdir $(LEAN_SRC_DIR) -cerberus_pp -lean \
    $(LEM_SRC_LEAN) 2> lean_frontend/lem.log || (>&2 cat lean_frontend/lem.log; exit 1)
	@# Workaround: Lem generates bogus `import Operators` from `open SEU.Operators` in core_run.lem
	$(Q)sed -i'' -e '/^import Operators$$/d' $(LEAN_SRC_DIR)/Core_run.lean
	@echo "[COPY] $(words $(LEAN_HANDWRITTEN)) hand-written Lean files ($(LEAN_HANDWRITTEN_MANIFEST)) into [$(LEAN_SRC_DIR)]"
	$(Q)cp $(addprefix lean_frontend/,$(LEAN_HANDWRITTEN)) $(LEAN_SRC_DIR)/
	$(Q)tools/check_handwritten_sync.sh
	@echo "[STAMP] recording Lean lem-sync content stamp"
	$(Q)tools/check_lem_sync.sh --record-lean

# Native C objects linked into lean_frontend executables (lakefile.toml
# moreLinkArgs). Compiled with the toolchain's leanc (hermetic clang).
# Lake does NOT track these .o files as link inputs, so after recompiling we
# delete the linked executables to force a relink on the next lake build.
# effect-retirement C1: fresh_int/debug/tags retired with their externs
# (supply threading / value passing / driver-local verbosity); md5 stays
# — the digest boundary remains (its opaque conversion is C2).
LEAN_NATIVE = md5
.PHONY: lean-native-obj
lean-native-obj:
	@echo "[LEANC] compiling lean_frontend/native objects"
	$(Q)cd lean_frontend && SYSROOT=$$(lake env printenv LEAN_SYSROOT) && \
	  for f in $(LEAN_NATIVE); do \
	    "$$SYSROOT/bin/leanc" -c -O2 native/$$f.c -o native/$$f.o || exit 1; \
	  done && rm -f .lake/build/bin/*

.PHONY: lean-build
lean-build: lean-prelude-src lean-native-obj
	@echo "[LAKE] building CerberusLean"
	@# Arc-7 S5c (audit-1 F4): lake runs under the cgroup memory cap
	@# (D7 rule; scripts/capped falls back loudly without systemd-run).
	$(Q)cd lean_frontend && ../scripts/capped lake build

.PHONY: clean-lean
clean-lean:
	$(Q)rm -rf $(LEAN_SRC_DIR)
	$(Q)rm -f lean_frontend/lem.log lean_frontend/lem_sync.sha256
####

.PHONY: clean-web distclean-web
clean-web:
	$(Q)rm -f webcerb.concrete webcerb.symbolic webcerb.vip cerberus-webserver
distclean-web:
	$(Q)rm -f public/dist/main.bundle.js public/dist/main.bundle.js.map
	$(Q)rm -f public/dist/style.bundle.css public/dist/style.bundle.css.map
	$(Q)rm -f public/package-lock.json
	$(Q)rm -rf public/node_modules/
	$(Q)rm -rf public/_deployment/

.PHONY: clean
clean: clean-web
	$(Q)rm -f coq/*.{glob,vo,vok}
	$(Q)rm -rf _build/

.PHONY: distclean
distclean: clean clean-prelude-src clean-sibylfs-src clean-lean distclean-web

.PHONY: cerberus-lib
cerberus-lib:
	@echo "[DUNE] cerberus-lib"
	$(Q)dune build $(DUNEFLAGS) cerberus-lib.install

.PHONY: install_lib
install_lib: cerberus-lib
	@echo "[DUNE] install cerberus-lib"
	$(Q)dune install cerberus-lib

.PHONY: install
install: install_lib cerberus
	@echo "[DUNE] install cerberus"
	$(Q)dune install cerberus

.PHONY: install-cheri
install-cheri: install_lib
	@echo "[DUNE] install cerberus-cheri"
	$(Q)dune install cerberus-cheri

.PHONY: uninstall
uninstall: cerberus
	@echo "[DUNE] uninstall cerberus"
	$(Q)dune uninstall cerberus
