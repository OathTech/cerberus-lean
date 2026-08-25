/-
  RelSem.RoundEval.Assembly — arc-18 C1 decomposition (2026-08-25).

  ABSTRACTION: THE LOOP COMMAND + WHOLE-RUN ASSEMBLY —
  `derive_rounds` (binder/pack setup, the attribute fence, the
  per-round mint loop, terminal detection) and the whole-run
  artifacts: the dnms chain, the relative ∀-fuel chain (the
  iter_compose feed), the scheduler offer (ndct), the final state
  and the driver iteration. Chains compose the ROUND EQUATIONS the
  lanes minted; the glue laws (dnms_round/dnms_terminal/ndct_offer1/
  driver2_done) are registered laws.

  Split from RoundEval.lean; code carried VERBATIM.

  House rules: no sorry, no axioms; meta code only.
-/
import RelSem.RoundEval.Rounds
import RelSem.RoundEval.Lanes

set_option autoImplicit false

namespace RelSem
namespace RoundEval

open Lean Lean.Meta Lean.Elab Lean.Elab.Command
open RelSem.DeriveState (throwFrontier provenanceNote)

/-! ## The loop command -/

/-- `derive_rounds id (bs…) using td tid from σ0 [upto N]` — see the
    module header. -/
syntax roundsUpto := " upto " num
syntax roundsAssuming := " assuming " ident+
syntax roundsChain := " chain"
syntax roundsBuilder := " builder"
syntax roundsFencing := " fencing " ident+

elab "derive_rounds " id:ident bs:bracketedBinder* assum:(roundsAssuming)? fenc:(roundsFencing)? " using " td:term:max tid:term:max " from " σ0:term upto:(roundsUpto)? chainTk:(roundsChain)? builderTk:(roundsBuilder)? : command => do
  let ns ← getCurrNamespace
  let baseName := ns ++ id.getId
  let maxRounds := match upto with
    | some u => (u.raw[1].isNatLit?).getD 256
    | none => 256
  let demandTerminal := upto.isNone
  let emitChainRel := chainTk.isSome
  builderMode.set builderTk.isSome
  runTermElabM fun _ => do
    Term.elabBinders bs fun fvars => do
      -- hypothesis mode: build the pack from the named binders
      let hypIdents : Array Syntax := match assum with
        | some a => a.raw[1].getArgs
        | none => #[]
      let mut baseRw : Array HypRw := #[]
      let mut arith : Array Expr := #[]
      let mut hypFVars : Array Expr := #[]
      for hid in hypIdents do
        let uname := hid.getId
        let some decl := (← getLCtx).findFromUserName? uname
          | throwError "derive_rounds: assuming-hypothesis {uname} is \
              not a binder of this command"
        let fv := decl.toExpr
        hypFVars := hypFVars.push fv
        let ty ← instantiateMVars decl.type
        unless ← Meta.isProp ty do
          throwError "derive_rounds: assuming-hypothesis {uname} is \
              not a Prop binder ({ty})"
        match ty.eq? with
        | some (_, l, r) => baseRw := baseRw.push { lhs := l, rhs := r, prf := fv }
        | none => arith := arith.push fv
      let mut valueFVars : Array Expr := #[]
      for fv in fvars do
        if ← Meta.isProp (← inferType fv) then
          unless hypFVars.contains fv do
            throwError "derive_rounds: Prop binder \
              {← Lean.Meta.ppExpr fv} is not named in the assuming \
              clause (every hypothesis must be declared)"
        else
          valueFVars := valueFVars.push fv
      -- THE ATTRIBUTE FENCE (measured, this slice; three iterations):
      -- whnf-unfolding a function whose body reads a kernel-stuck
      -- extern EXPLODES the spelling through recursor branches and
      -- Decidable-instance PROOFS, and substituting inside those
      -- dependent positions builds ILL-TYPED terms (kernel
      -- application-type-mismatch at addDecl; probe: post-subst
      -- isDefEq _ 8 = false). A canUnfold?-hook fence cannot mirror
      -- default unfolding (smart-unfolding/WF gating lives outside
      -- it — 200k-heartbeat death in raw Acc.rec towers). The working
      -- fence: TEMPORARY @[irreducible] status on the pack's
      -- pattern-head constants for the drive's extent (restored at
      -- every exit — success paths restore before the env is
      -- serialized; a failed drive fails the module anyway). The
      -- elaborator then stops at the TIDY curated spellings, where
      -- substitution is a well-typed data-position rewrite; the
      -- KERNEL is attribute-blind, so emitted proofs check exactly
      -- as before.
      let fence : NameSet := {}
      let mut fenceSaved : Array (Name × ReducibilityStatus) := #[]
      let mut fenceHeadSet : NameSet := {}
      for r in baseRw do
        if let .const c _ := r.lhs.getAppFn then
          fenceHeadSet := fenceHeadSet.insert c
          unless fenceSaved.any (·.1 == c) do
            fenceSaved := fenceSaved.push (c, ← getReducibilityStatus c)
            setReducibilityStatus c .irreducible
      -- explicit `fencing f g …` heads (arc-17 S3): spelling
      -- preservation for constructs the pack reasons about by LAW
      -- rather than rewrite (e.g. `fmapAddBy` chains over a free env
      -- binder, consumed by the env-lookup lane); ground occurrences
      -- still compute via the fenced-head ground escape.
      if let some ftk := fenc then
        for fid in ftk.raw[1].getArgs do
          let cs ← realizeGlobalConstNoOverload fid
          fenceHeadSet := fenceHeadSet.insert cs
          unless fenceSaved.any (·.1 == cs) do
            fenceSaved := fenceSaved.push (cs, ← getReducibilityStatus cs)
            setReducibilityStatus cs .irreducible
      baseFenceHeads.set fenceHeadSet
      let hp : HypPack :=
        { baseRw, arith, minted := ← IO.mkRef #[],
          mintIdx := ← IO.mkRef 0,
          baseName := baseName.appendAfter "_hf",
          fvars, valueFVars, fence,
          defeqSubst := ← IO.mkRef #[] }
      -- ref hygiene: the pack is SET unconditionally at every command
      -- start (a failed prior command cannot leak a stale pack into
      -- this one) and cleared at the exits below; a module abort
      -- between the two fails the build anyway.
      if hypIdents.isEmpty then
        activeHypPack.set none
      else
        activeHypPack.set (some hp)
      let tdE ← Term.elabTerm td none
      let tidE ← Term.elabTerm tid (some (mkConst ``Nat))
      let σ0E ← Term.elabTerm σ0 none
      Term.synthesizeSyntheticMVarsNoPostponing
      let tdE ← instantiateMVars tdE
      let tidE ← instantiateMVars tidE
      let σ0E ← instantiateMVars σ0E
      let tdS ← toStxU tdE
      let tidS ← toStxU tidE
      let mut σ := σ0E
      -- anchor on the LITERAL record fields when σ0 unfolds to one
      -- (arc-17 S3): projection-spelled components re-force the
      -- whole state per use — for a ladder-carrying memory field the
      -- head whnf then chains through every layer in one unit
      -- (measured: the T5 body walk's memMat initialization)
      let σ0R ← unfoldToRecord σ0E
      let mut anchor ←
        (if σ0R.isAppOfArity ``driver_state.mk 11 then do
          let a := σ0R.getAppArgs
          pure { cs := a[2]!, rs := a[3]!, mem := a[4]!,
                 memMat := a[4]!, tr := a[7]!, ctr := a[10]!,
                 fixed := #[a[0]!, a[1]!, a[5]!, a[6]!, a[8]!, a[9]!] }
        else Anchor.init σ0E)
      -- hyp mode: materialize the initial memory ONCE (the twin's
      -- base; ~1.4 s at T4's 4-layer ready ladder — measured within
      -- the default budget; every later update is a delta pass)
      if !hypIdents.isEmpty then
        trace[RelSem.roundEval] "memMat init: start"
        let mat ← withCurrHeartbeats
          (groundNorm "initial memMat" anchor.mem)
        trace[RelSem.roundEval] "memMat init: done ({← mat.numObjs} objs)"
        hp.defeqSubst.modify (·.push (anchor.mem, mat))
        anchor := { anchor with memMat := mat }
      let mut rounds : Array MintedRound := #[]
      let mut terminal : Option Expr := none  -- the offered steps list
      -- One round's mint, under its OWN default heartbeat budget
      -- (`withCurrHeartbeats`): the loop is sugar for one command per
      -- round, and a shared per-command budget would make capacity
      -- depend on how many rounds a program happens to run — NOT a
      -- budget raise (each unit keeps the default; a single round
      -- exceeding it still fails loudly).
      let mintOne := fun (k : Nat) (σ : Expr) (anchor : Anchor) =>
        withCurrHeartbeats (do
        let t0 ← IO.monoMsNow
        let stepAtE ← mkAppMU ``RelSem.Laws.stepAt #[tdE, tidE, σ]
        -- classification is DEFEQ-PURE by design (hyp mode included):
        -- the discovered step's spelling enters the round equation's
        -- conclusion through the law's m_request argument, so any
        -- hypothesis substitution here would break the kernel's defeq
        -- bridge (measured this slice: rT5 kernel type mismatch).
        -- Stuck data inside a state never reaches classification —
        -- the PRODUCING round's respell bridge (emitLawRound) cleans
        -- it before the successor is named.
        trace[RelSem.roundEval] "round {k}: classifying"
        let stepE ← (do
          try
            let r ← whnf stepAtE
            -- fence fallback (arc-17 S3): classification is
            -- DEFEQ-PURE by design, so when the default-transparency
            -- whnf is blocked by the hyp-mode fences (a ground
            -- lookup inside step discovery), re-classify at `.all`
            -- (attribute-blind) — the pre-fence behavior exactly
            let isStep (e : Expr) : Bool :=
              e.isAppOf ``core_step2.Step_action_request2
                || e.isAppOf ``core_step2.Step_blocked2
                || e.isAppOf ``core_step2.Step_tau2
                || e.isAppOf ``core_step2.Step_with_runstate2
            if isStep r then
              pure r
            else
              let r2 ← withCurrHeartbeats
                (withTransparency .all (whnf stepAtE))
              if isStep r2 then
                pure r2
              else
                -- HYP-AWARE classification (arc-17 S3): at a
                -- builder-state σ0 the discovery itself can consult
                -- the free components (step_ctx reads layout_state —
                -- the S3-record open question, measured at the T5
                -- body's post-store round); the pack normalizes it,
                -- and the discovery GLUE (elabLawChain) carries the
                -- matching PROVED equation instead of a refl hint.
                hypNormA "classification" r
          catch ex =>
            throwError "derive_rounds: round {k} CLASSIFICATION \
              failed/timed out: {ex.toMessageData}")
        trace[RelSem.roundEval] "round {k}: classify {(← IO.monoMsNow) - t0} ms"
        let declName := baseName.appendAfter (toString k)
        if stepE.isAppOf ``core_step2.Step_action_request2 then
          let lhs ← mkRoundLhs tdE tidE σ
          let (r, a') ← mintMemRound declName fvars anchor tdE tidE σ lhs stepE k
          trace[RelSem.roundEval] "round {k}: {r.cls} ({(← IO.monoMsNow) - t0} ms)"
          return Sum.inl (r, a')
        else if stepE.isAppOf ``core_step2.Step_blocked2 then
          -- No advancing step: the terminal offer (or a genuine block).
          let σS ← toStxU σ
          let stepsE ← evalGroundA s!"terminal offer (round {k})" <|
            ← elabClosed (← `(step_ctx $tdS
              (driver_state.layout_state $σS)
              (driver_state.core_file $σS)
              (driver_state.core_extern $σS) $tidS
              ((Lem_List.lookupBy (fun (x y : Nat) => x == y) $tidS
                (core_state.thread_states
                  (driver_state.core_state0 $σS))).getD default)))
          return Sum.inr stepsE
        else
          let lhs ← mkRoundLhs tdE tidE σ
          let (r, a') ← mintLawPure declName fvars anchor tdE tidE σ lhs stepE k
          trace[RelSem.roundEval] "round {k}: {r.cls} ({(← IO.monoMsNow) - t0} ms)"
          return Sum.inl (r, a') :
          TermElabM (Sum (MintedRound × Anchor) Expr))
      for k in [1 : maxRounds + 1] do
        match ← mintOne k σ anchor with
        | .inl (r, a') =>
          rounds := rounds.push r
          σ := r.succ
          anchor := a'
        | .inr stepsE =>
          terminal := some stepsE
          break
      let classes := rounds.map (·.cls)
      logInfo m!"derive_rounds {baseName}: {rounds.size} advancing \
        rounds minted; classes: {classes}"
      -- THE RELATIVE CHAIN (arc-17 S3, opt-in `chain` token): the
      -- iter_compose feed — a ∀-fuel composable block equation. The
      -- dnms laws are already fuel-relative (`hfuel : fuelS = fuel+1`
      -- discharges by rfl at `fuel + m ≟ (fuel + (m-1)) + 1`), so the
      -- chain states
      --   ∀ fuel, app (dnms (fuel + N) …) σ0 = app (dnms fuel …) σN
      -- (partial mode), or, when the terminal offer was reached,
      --   ∀ fuel, app (dnms (fuel + N + 2) …) σ0 = (NDactive offer, σN)
      -- — the shapes T5-by-invariant's loop composition consumes.
      if emitChainRel then withCurrHeartbeats do
        let n := rounds.size
        let σ0S ← toStxU σ0E
        let succS ← toStxU σ
        let accS ← `(fmapEmpty)
        let fuelId := mkIdent `fuel
        let mkF (m : Nat) : TermElabM Term :=
          if m == 0 then pure fuelId
          else `($fuelId + $(Syntax.mkNatLit m))
        let off := if terminal.isSome then 2 else 0
        let mut pf? : Option Term := none
        for j in [0 : n] do
          let fS ← mkF (n + off - j)
          let f1S ← mkF (n + off - j - 1)
          let hadvS ← toStxU (mkAppN (mkConst rounds[j]!.eqName) fvars)
          let step ← `(RelSem.Kit.dnms_round (fuelS := $fS)
            (fuel := $f1S) rfl rfl rfl rfl $hadvS)
          pf? := some (← match pf? with
            | none => pure step
            | some p => `(($p).trans $step))
        let (stmtStx, pfStx) ← (do
          match terminal with
          | none =>
            let stmtStx ← `(∀ ($fuelId : Nat), RelSem.app
                (drive_nonmemory_steps_aux2_lemFuel
                  ($fuelId + $(Syntax.mkNatLit n)) $tdS $accS [$tidS]) $σ0S
              = RelSem.app (drive_nonmemory_steps_aux2_lemFuel $fuelId
                  $tdS $accS [$tidS]) $succS)
            let body := pf?.get!
            pure (stmtStx, ← `(fun ($fuelId : Nat) => $body))
          | some stepsE =>
            let stepsS ← toStxU stepsE
            let termS ← `(RelSem.Kit.dnms_terminal
              (fuelS := $(← mkF 2)) (fuel := $fuelId)
              (steps := $stepsS) rfl rfl rfl rfl)
            let whole ← match pf? with
              | none => pure termS
              | some p => `(($p).trans $termS)
            let stmtStx ← `(∀ ($fuelId : Nat), RelSem.app
                (drive_nonmemory_steps_aux2_lemFuel
                  ($fuelId + $(Syntax.mkNatLit (n + 2))) $tdS $accS
                  [$tidS]) $σ0S
              = (NDactive (fmapAddBy defaultCompare $tidS $stepsS
                  fmapEmpty), $succS))
            pure (stmtStx, ← `(fun ($fuelId : Nat) => $whole)))
        let stmt ← Term.elabType stmtStx
        Term.synthesizeSyntheticMVarsNoPostponing
        let stmt ← instantiateMVars stmt
        let pf ← Term.elabTermEnsuringType pfStx stmt
        Term.synthesizeSyntheticMVarsNoPostponing
        let chainName := baseName.appendAfter "_chainrel"
        emitThm chainName fvars stmt (← instantiateMVars pf)
          s!"RELATIVE {if terminal.isSome then "terminal " else ""}chain \
             ({rounds.size} rounds{if terminal.isSome then " + terminal" else ""}, \
             ∀-fuel — the iter_compose feed). \
             {provenanceNote "derive_rounds"}"
        logInfo m!"derive_rounds {baseName}: relative chain {chainName} \
          emitted ({rounds.size} rounds, terminal={terminal.isSome})"
      match terminal with
      | none =>
        activeHypPack.set none
        builderMode.set false
        baseFenceHeads.set {}
        for (c, st) in fenceSaved do
          setReducibilityStatus c st
        if demandTerminal then
          throwFrontier m!"derive_rounds: no terminal within \
            {maxRounds} rounds (partial mode requires `upto`)"
      | some stepsE => withCurrHeartbeats do
        -- The whole-run chain, the scheduler offer, the driver
        -- iteration (own budget scope, same rationale as per-round).
        let n := rounds.size
        let vE ← terminalValue stepsE n
        let accS ← `(fmapEmpty)
        let σ0S ← toStxU σ0E
        let stepsS ← toStxU stepsE
        -- chain statement:
        --   app (dnms lemDefaultFuel td fmapEmpty [tid]) σ0
        --     = (NDactive (fmapAddBy defaultCompare tid steps fmapEmpty),
        --        rN)
        let succS ← toStxU σ  -- final advancing state (rN)
        let chainStmtStx ← `(RelSem.app
          (drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel $tdS
            $accS [$tidS]) $σ0S
          = (NDactive (fmapAddBy defaultCompare $tidS $stepsS fmapEmpty),
             $succS))
        -- chain proof: dnms_round per round (descending fuel literals),
        -- dnms_terminal at the end.
        let fuel0E ← withTransparency .all <|
          whnf (← evalGround "lemDefaultFuel" (mkConst ``lemDefaultFuel))
        let some fuel0 := fuel0E.rawNatLit? <|> fuel0E.nat?
          | throwError "derive_rounds: lemDefaultFuel did not reduce to \
              a literal:{indentExpr fuel0E}"
        let mut proofStx : Term ← do
          let fS := Syntax.mkNatLit (fuel0 - n)
          let f2S := Syntax.mkNatLit (fuel0 - n - 2)
          `(RelSem.Kit.dnms_terminal (fuelS := $fS) (fuel := $f2S)
              (steps := $stepsS) rfl rfl rfl rfl)
        for i in [0 : n] do
          let k := n - 1 - i
          let fS := Syntax.mkNatLit (fuel0 - k)
          let f1S := Syntax.mkNatLit (fuel0 - k - 1)
          let hadvS ← toStxU
            (mkAppN (mkConst rounds[k]!.eqName) fvars)
          proofStx ← `((RelSem.Kit.dnms_round (fuelS := $fS)
            (fuel := $f1S) rfl rfl rfl rfl $hadvS).trans $proofStx)
        let chainStmt ← Term.elabType chainStmtStx
        Term.synthesizeSyntheticMVarsNoPostponing
        let chainStmt ← instantiateMVars chainStmt
        let chainPf ← Term.elabTermEnsuringType proofStx chainStmt
        Term.synthesizeSyntheticMVarsNoPostponing
        let chainName := baseName.appendAfter "_chain"
        emitThm chainName fvars chainStmt (← instantiateMVars chainPf)
          s!"The whole dnms run ({n} law/mint rounds + terminal). \
             {provenanceNote "derive_rounds"}"
        -- scheduler offer via ndct_offer1
        let vS ← toStxU vE
        let chainS ← toStxU (mkAppN (mkConst chainName) fvars)
        let ndctStmtStx ← `(RelSem.app
          (new_drive_core_threads $tdS ()) $σ0S
          = (NDactive [($tidS, some (Step_done2 $vS))], $succS))
        let ndctPfStx ← `(RelSem.Laws.ndct_offer1 rfl $chainS)
        let ndctStmt ← Term.elabType ndctStmtStx
        Term.synthesizeSyntheticMVarsNoPostponing
        let ndctPf ← Term.elabTermEnsuringType ndctPfStx
          (← instantiateMVars ndctStmt)
        Term.synthesizeSyntheticMVarsNoPostponing
        let ndctName := baseName.appendAfter "_ndct"
        emitThm ndctName fvars (← instantiateMVars ndctStmt)
          (← instantiateMVars ndctPf)
          s!"The scheduler sees exactly the done offer (via \
             Laws.ndct_offer1). {provenanceNote "derive_rounds"}"
        -- final driver state + one driver2 iteration via driver2_done
        let finStx ← `({ $succS with
          core_state0 := prepare_exit
            (driver_state.core_state0 $succS) $vS })
        let finE ← Term.elabTerm finStx none
        Term.synthesizeSyntheticMVarsNoPostponing
        let finName := baseName.appendAfter "_fin"
        let dataFVars ← match ← activeHypPack.get with
          | some hp => pure hp.valueFVars
          | none => pure fvars
        emitFlatDef finName dataFVars (← instantiateMVars finE)
          s!"The final driver state (post prepare_exit). \
             {provenanceNote "derive_rounds"}"
        let finS ← toStxU (mkAppN (mkConst finName) dataFVars)
        let ndctS ← toStxU (mkAppN (mkConst ndctName) fvars)
        let fm1S := Syntax.mkNatLit (fuel0 - 1)
        let drvStmtStx ← `(RelSem.app (driver2 $tdS false) $σ0S
          = (NDactive (), $finS))
        let drvPfStx ← `(RelSem.Laws.driver2_done (fuel := $fm1S)
          $ndctS rfl)
        let drvStmt ← Term.elabType drvStmtStx
        Term.synthesizeSyntheticMVarsNoPostponing
        let drvPf ← Term.elabTermEnsuringType drvPfStx
          (← instantiateMVars drvStmt)
        Term.synthesizeSyntheticMVarsNoPostponing
        let drvName := baseName.appendAfter "_driver"
        emitThm drvName fvars (← instantiateMVars drvStmt)
          (← instantiateMVars drvPf)
          s!"One driver2 iteration is the whole run (via \
             Laws.driver2_done). {provenanceNote "derive_rounds"}"
        logInfo m!"derive_rounds {baseName}: terminal reached after \
          {n} rounds; emitted {chainName}, {ndctName}, {finName}, \
          {drvName}"
      activeHypPack.set none
      builderMode.set false
      baseFenceHeads.set {}
      for (c, st) in fenceSaved do
        setReducibilityStatus c st

end RoundEval
end RelSem
