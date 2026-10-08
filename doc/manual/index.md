# linear-program

This manual documents the `v0.1.0` release of `linear-program`, as migrated to MoonBit 0.10 on `main`.

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/linear-program/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## Overview

linear-program is a [MoonBit](https://www.moonbitlang.com/) library for writing linear programs and solving them with the two-phase simplex method. Coefficients are generic over the algebraic traits of [luna-generic](https://lunaflow.cn/en/luna-generic/), and the simplex tableau is a mutable matrix from [linear-algebra](https://lunaflow.cn/en/linear-algebra/). Every step of the solver is public, so the library also serves to follow the simplex method by hand.

The solver is a teaching implementation. It handles small, well-scaled programs with `Double` coefficients, but it has known defects that can make it report a wrong optimum, a point that violates a constraint, or a false "unbounded"; the [API](api/core.md) marks each with a warning and the [design notes](design/core.md#known-defects) explain them.

## Install

The module is named `linear-program`, without the `Luna-Flow/` namespace, so it is not published as `Luna-Flow/linear-program` on mooncakes yet and `moon add` cannot fetch it. Use a local checkout instead: add it, together with checkouts of `luna-generic` and `linear-algebra`, to the `members` of your `moon.work`, and list it in the `import` block of your `moon.mod`:

```moonbit nocheck
import {
  "linear-program@0.1.0",
  "Luna-Flow/linear-algebra@0.4.7",
}
```

Then import `"linear-program"` in your `moon.pkg`; the [tutorial](tutorial/core.md#quick-start) shows the complete setup. The library needs the MoonBit toolchain 0.10 or later (`moonc` ≥ 0.10) and depends on `Luna-Flow/luna-generic` 0.3.3 and `Luna-Flow/linear-algebra` 0.4.7.

## Pages

All public names live in the single package at `src`, documented as `core`.

| Part | Tutorial | API | Design |
| --- | --- | --- | --- |
| `core`: programs, standard form, the two-phase simplex solver | [tutorial](tutorial/core.md) | [API](api/core.md) | [design](design/core.md) |
| Contribution guidelines | | | [contributing](contributing.md) |

## Modelling

- `Variable`: a named decision variable; its bounds are stored but not enforced
- `Poly`: a linear expression, a map from variables to non-zero coefficients
- `Obj_func`: an objective, a `Poly` with the sense `min` or `max`
- `Constraint`: equalities and `<=` / `>=` inequalities

## Programs and standard form

- `Lp`: a program with its variables, objective, constraints and program matrix
- `Lp::new`, `Lp::cons_from_Array`, `Lp::reset_obj_byarray`, `Lp::from_matrix`: build a program
- `Lp::to_standard`: rewrite it as $\min c^\top x$, $Ax = b$, $b \ge 0$, $x \ge 0$
- `Lp::get_coeff_matrix`, `Lp::get_objfunc_vector`, `Lp::get_b_vector`: read $A$, $c$, $b$

## Solver

- `Lp::two_stage`: the two-phase simplex method on a program in standard form
- `Lp::pivot`, `Lp::simplex_iteration`, `Lp::phase_1`, `Lp::phase_2`: its steps, public for teaching
- `ApproximatelyZero`, `double_equal_to_zero`: the zero test of phase 2, implemented for `Int` and `Double`

## Where to read next

The [tutorial](tutorial/core.md) solves a production problem, a minimisation with `>=` constraints and a program given as a matrix, then pivots a tableau by hand. The [API reference](api/core.md) states the exact behaviour of every function, including what aborts, and the [design notes](design/core.md) derive standard form, reduced costs, the stopping tests and the two phases.

- New to linear programming: work through the [tutorial](tutorial/core.md), and keep the [design notes](design/core.md) open for the meaning of standard form, reduced costs and the two phases.
- Using the solver in a library: read the warnings in the [API reference](api/core.md) and the [common pitfalls](tutorial/core.md#common-pitfalls), and check every result against the constraints, as the tutorial shows.
- Contributing: read the [design notes](design/core.md), especially the invariants and the known defects, then the [contribution guidelines](contributing.md).

## Validation

Recommended release checks, from the repository root (or run `ready_to_pr.sh`):

```bash
moon fmt
moon check --target all
moon info
moon test
```
