# core design

linear-program keeps variables, linear expressions, objectives, constraints and the solver in one package at `src`. This page explains how a program is represented and how it is solved.

## Representation

A program is described twice. The symbolic description is an objective (`Obj_func`) and a constraint set (`Constraint`), both built from linear expressions (`Poly`) over named variables. The numeric description is the program matrix: row 0 holds the objective coefficients, every other row holds one equality constraint, and the last column holds the right-hand sides.

Every function that builds an `Lp` rebuilds the matrix from the symbolic description, and `Lp::from_matrix` goes the other way. A program can therefore be written either way and printed in readable form with `Show`.

A linear expression is a sorted map from variables to coefficients. Variables are identified and ordered by name alone, and zero coefficients are never stored, so adding a term that cancels an existing one removes it.

## Standard form

The solver works on the standard form

$$
\min\, c^\top x \quad \text{subject to} \quad A x = b,\; b \ge 0,\; x \ge 0 .
$$

`Lp::to_standard` produces it: a maximisation objective is negated, a constraint with a negative right-hand side is multiplied by $-1$, and every inequality receives its own slack or surplus variable, named `y1`, `y2`, ... in order. Variable bounds are kept for display, but the standard form assumes $x \ge 0$ for every variable.

## Two-phase simplex

`Lp::two_stage` solves the standard form in two phases on a dense tableau.

1. Phase 1 adds an artificial variable to every row that has no unit column yet and minimises the sum of the artificial variables (`Lp::phase_1`). A non-zero optimum means that the program is infeasible.
2. Phase 2 drops the artificial columns, restores the original objective, eliminates the basic columns from the objective row and runs the simplex method again (`Lp::phase_2`).

Both phases use `Lp::simplex_iteration`: Dantzig's rule picks the column with the most negative objective coefficient, the minimum ratio test picks the row, and `Lp::pivot` performs a Gauss–Jordan step. The steps are public so that a tableau can be examined or driven by hand.

Floating-point tableaux rarely produce exact zeros, so phase 2 compares values with `ApproximatelyZero`, which treats a `Double` below $10^{-15}$ in absolute value as zero.

## Boundaries

- Errors are not values. Infeasible and unbounded programs, a zero pivot and invalid arguments abort the program.
- Variable bounds other than $x \ge 0$ are not enforced.
- There is no anti-cycling rule beyond the iteration limit of 1000 per simplex run.
- The tableau is dense; the package does not exploit sparsity.
- Integer and mixed-integer programming are out of scope.
