# core design

linear-program keeps variables, linear expressions, objectives, constraints and a two-phase simplex solver in one package at `src`. This page states the mathematics the solver implements, derives the tests it uses to stop, and explains how the code is organised around them.

## Design goal

- Let a user write a linear program in the notation of a textbook: named variables, an objective with a sense, and equality and inequality constraints.
- Solve it with the textbook algorithm, the two-phase simplex method on a dense tableau, and expose every step (`Lp::pivot`, `Lp::simplex_iteration`, `Lp::phase_1`, `Lp::phase_2`) so that the algorithm can be followed and taught.
- Stay generic in the coefficient type through the traits of [luna-generic](https://lunaflow.cn/en/luna-generic/), and store tableaux as matrices of [linear-algebra](https://lunaflow.cn/en/linear-algebra/).

## Mathematical background

### Linear programs and standard form

A linear program over variables $x \in \mathbb{R}^n$ optimises a linear objective subject to linear equalities and inequalities. The solver works on the *standard form*

$$
\min_{x \in \mathbb{R}^n} \; c^\top x \quad \text{subject to} \quad A x = b, \quad x \ge 0, \qquad A \in \mathbb{R}^{m \times n},\; b \in \mathbb{R}^m_{\ge 0}.
$$

Every program written with this package can be brought into this form without changing its optimal solutions. `Lp::to_standard` applies these rewritings:

$$
\begin{aligned}
\max\; c^\top x &= -\min\; (-c)^\top x, \\
a^\top x = \beta,\ \beta < 0 \quad &\Longleftrightarrow \quad (-a)^\top x = -\beta, \\
a^\top x \le \beta,\ \beta \ge 0 \quad &\Longleftrightarrow \quad a^\top x + y = \beta,\ y \ge 0, \\
a^\top x \le \beta,\ \beta < 0 \quad &\Longleftrightarrow \quad (-a)^\top x - y = -\beta,\ y \ge 0, \\
a^\top x \ge \beta,\ \beta > 0 \quad &\Longleftrightarrow \quad a^\top x - y = \beta,\ y \ge 0, \\
a^\top x \ge \beta,\ \beta \le 0 \quad &\Longleftrightarrow \quad (-a)^\top x + y = -\beta,\ y \ge 0.
\end{aligned}
$$

Each equivalence holds because $y$ measures the slack of the inequality: for $a^\top x \le \beta$, set $y = \beta - a^\top x$, which is non-negative exactly when the inequality holds. Multiplying an equation by $-1$ changes nothing, and multiplying an inequality by $-1$ reverses it, which is why the sign of the slack variable flips in the cases with $\beta < 0$ and $\beta \le 0$. In every case the new right-hand side is non-negative, which phase 1 needs.

The standard form assumes $x \ge 0$ for *every* variable, including the variables of the original program. The bounds stored in `Variable` are not used.

### Bases and basic solutions

Assume $A$ has rank $m$. A *basis* is a set $B$ of $m$ column indices such that the submatrix $A_B$ is invertible; the remaining indices form $N$. Setting the non-basic variables to zero determines the *basic solution*

$$
x_N = 0, \qquad x_B = A_B^{-1} b,
$$

which is *feasible* when $x_B \ge 0$. The fundamental theorem of linear programming states that if the program has an optimal solution, it has an optimal basic feasible solution, so the simplex method only visits bases.[^fundamental]

[^fundamental]: See for example Chvátal, *Linear Programming* (1983), chapter 3, or Bertsimas and Tsitsiklis, *Introduction to Linear Optimization* (1997), theorem 2.7.

### The tableau and reduced costs

The solver stores the program as an $(m + 1) \times (n + 1)$ tableau:

$$
T = \begin{bmatrix} c^\top & 0 \\ A & b \end{bmatrix}.
$$

Row 0 is the objective row, rows $1, \dots, m$ are the constraints, and the last column holds right-hand sides. A *pivot* on position $(r, s)$ with $T_{rs} \ne 0$ is a Gauss–Jordan step: divide row $r$ by $T_{rs}$, then subtract $T_{is}$ times the new row $r$ from every other row $i$, including row 0. Afterwards column $s$ is the unit vector $e_r$. This is exactly `Lp::pivot`.

Suppose a sequence of pivots has made the columns of a basis $B$ into unit vectors. Every pivot is a left multiplication by an invertible matrix, and row 0 has only received multiples of constraint rows, so the tableau has the form

$$
T_B = \begin{bmatrix} c^\top - y^\top A & -y^\top b \\ A_B^{-1} A & A_B^{-1} b \end{bmatrix}
$$

for some vector $y \in \mathbb{R}^m$. The basic columns of row 0 are zero, so $c_B^\top - y^\top A_B = 0$, that is

$$
y^\top = c_B^\top A_B^{-1}.
$$

Substituting $y$ gives the canonical tableau

$$
T_B = \begin{bmatrix} \bar c^\top & -z_B \\ \bar A & \bar b \end{bmatrix},
\qquad
\bar c^\top = c^\top - c_B^\top A_B^{-1} A, \quad
z_B = c_B^\top A_B^{-1} b, \quad
\bar A = A_B^{-1} A, \quad
\bar b = A_B^{-1} b.
$$

The entries $\bar c_j$ are the *reduced costs*, $\bar b = x_B$ is the basic solution, and the last entry of row 0 is the *negated* objective value $-z_B = -c^\top x$. This is why `Lp::phase_2` returns $-z$ and why `Lp::two_stage` negates it again for a minimisation objective.

The reduced costs describe how the objective changes along the constraints. For any $x$ with $Ax = b$, solve for the basic variables: $x_B = \bar b - A_B^{-1} A_N x_N$. Then

$$
\begin{aligned}
c^\top x &= c_B^\top x_B + c_N^\top x_N \\
&= c_B^\top \bar b - c_B^\top A_B^{-1} A_N x_N + c_N^\top x_N \\
&= z_B + \bar c_N^\top x_N .
\end{aligned}
$$

### Optimality

**If $\bar c \ge 0$, the basic feasible solution is optimal.** Every feasible $x$ satisfies $x_N \ge 0$, so by the identity above $c^\top x = z_B + \bar c_N^\top x_N \ge z_B$, and the basic solution attains $z_B$. `Lp::simplex_iteration` stops when no entry of row 0 is negative, which is this test ($\bar c_B = 0$ holds by construction).

### Choosing the entering column

If some $\bar c_s < 0$, increasing $x_s$ from $0$ decreases the objective at rate $|\bar c_s|$. The solver chooses the most negative reduced cost,

$$
s = \operatorname*{arg\,min}_{j} \; \bar c_j, \qquad \bar c_s < 0,
$$

Dantzig's rule, and takes the leftmost column on ties.

### The ratio test and unboundedness

Increase $x_s$ to $t \ge 0$ and keep the other non-basic variables at zero. The constraints force $x_B(t) = \bar b - t\, \bar a_s$, where $\bar a_s$ is column $s$ of $\bar A$, and the objective becomes $z_B + t\, \bar c_s$.

**If $\bar a_s \le 0$, the program is unbounded.** Every component of $x_B(t)$ is non-decreasing in $t$, so $x(t)$ is feasible for all $t \ge 0$ while $z_B + t\,\bar c_s \to -\infty$. `Lp::simplex_iteration` aborts with `Problem is unbounded` in this case.

Otherwise feasibility requires $\bar b_i - t\, \bar a_{is} \ge 0$ for every row with $\bar a_{is} > 0$, so the largest step is

$$
t^\ast = \min_{i \,:\, \bar a_{is} > 0} \frac{\bar b_i}{\bar a_{is}},
$$

the *minimum ratio test*. A row $r$ attaining the minimum leaves the basis: its basic variable reaches zero at $t^\ast$. Pivoting on $(r, s)$ moves to the new basis $B' = B \setminus \{B_r\} \cup \{s\}$, whose basic solution is $x(t^\ast) \ge 0$, so feasibility is preserved, and whose objective value is

$$
z_{B'} = z_B + t^\ast\, \bar c_s \le z_B .
$$

The solver takes the topmost row on ties.

### Termination and degeneracy

If every pivot has $t^\ast > 0$ (the program is *non-degenerate*), the objective strictly decreases, no basis repeats, and the method stops after at most $\binom{n}{m}$ pivots. When $\bar b_r = 0$ for the leaving row, $t^\ast = 0$: the basis changes but the point and the objective do not. A sequence of such degenerate pivots can return to an earlier basis and repeat forever. Dantzig's rule with lowest-index tie-breaking, which is what this package implements, is known to cycle on small examples.[^cycling] The package has no anti-cycling rule; a run stops after `max_iterations` pivots (1000 by default) and prints a message, and the tableau it returns is then not optimal.

[^cycling]: E. M. L. Beale, "Cycling in the dual simplex algorithm", *Naval Research Logistics Quarterly* 2 (1955), gives a cycling example with three constraints. R. G. Bland, "New finite pivoting rules for the simplex method", *Mathematics of Operations Research* 2 (1977), proves that choosing, among the candidates, the entering and the leaving variable with the smallest index prevents cycling.

## Design decisions

### Two phases with artificial variables

**Problem.** The simplex method starts from a basic feasible solution, and a program in standard form does not come with one.

**Options.** (a) The big-M method: add artificial variables with a large cost $M$ to the original objective. (b) The two-phase method: first find a feasible basis with an auxiliary objective, then optimise. (c) Require the user to supply a feasible basis.

**Choice.** (b). Big-M needs a numeric value of $M$ that is large enough for the program but small enough not to swamp the other coefficients in floating point; the two-phase method needs no such constant, and its first phase also decides feasibility.

**Phase 1.** For every constraint row $i$ that has no usable unit column, add an artificial variable $a_i \ge 0$ with coefficient $1$ in row $i$. Let $R$ be the set of these rows. Phase 1 solves

$$
\min\; w = \sum_{i \in R} a_i \quad \text{subject to} \quad A x + \sum_{i \in R} a_i e_i = b, \quad x \ge 0,\ a \ge 0 .
$$

Its initial basis consists of the artificial columns and the existing unit columns, with the basic solution $x_B = b \ge 0$, which is feasible because `to_standard` made $b$ non-negative.

*The original program is feasible exactly when the optimum of phase 1 is $w^\ast = 0$.* If $x$ is feasible for $Ax = b$, then $(x, a = 0)$ is feasible for phase 1 with $w = 0$, and $w \ge 0$ always, so $w^\ast = 0$. Conversely, $w^\ast = 0$ with $a \ge 0$ forces $a = 0$, so the optimal $x$ satisfies $Ax = b$.

**Canonical form of the phase 1 tableau.** Row 0 of the phase 1 objective starts as $[\,0 \mid \mathbf 1^\top \mid 0\,]$, which is not canonical because the basic artificial columns have cost $1$. Applying the formula $y^\top = c_B^\top A_B^{-1}$ with $A_B = I$ gives $y = \mathbf 1_R$, so the canonical row 0 is

$$
\Bigl[\; -\sum_{i \in R} A_{i\cdot} \;\Big|\; 0 \;\Big|\; -\sum_{i \in R} b_i \;\Bigr],
$$

obtained by subtracting each artificial row from row 0. `Lp::phase_1` performs exactly these subtractions before calling `simplex_iteration`.

**Phase 2.** If $w^\ast \ne 0$ (beyond the tolerance below), `Lp::phase_2` aborts: the program is infeasible. Otherwise it drops the artificial columns, writes the original costs $c$ into row 0, and makes row 0 canonical again by subtracting $c_j$ times the row of each basic column $j$, which is the same elimination as above. Then it runs `simplex_iteration` from the feasible basis found by phase 1.

### Reusing unit columns as the initial basis

A slack variable of a `<=` row with $b \ge 0$ has a column equal to a unit vector, so it can start in the basis without an artificial variable. The private helper that builds the phase 1 tableau recognises a column as a unit column when one entry equals $1$ and all other entries in the constraint rows are $0$, and adds artificial variables only for the remaining rows. A program whose constraints are all `<=` with non-negative right-hand sides therefore needs no artificial variables at all, and phase 1 is skipped in effect: its tableau keeps the original objective, so phase 1 already optimises it.

### Dense tableau

The tableau is a dense `@mutable.Matrix`. Each pivot costs $(m + 1)(n + 1)$ multiply–subtract operations, $O(mn)$. A revised simplex method with a factorised basis would cost less per iteration on sparse programs, but the dense tableau shows every quantity of the derivation above as an entry of one matrix, which serves the teaching goal of the package and keeps the code short.

### Aborting instead of returning errors

Infeasible and unbounded programs, a zero pivot, an unknown objective sense and an unknown relation string end the program with `abort`. The package predates the Luna-Flow convention of returning `Result` with a structured error. Callers cannot recover from these outcomes; see the boundaries below.

### Numeric tolerance

The simplex iterations compare entries with zero exactly: a reduced cost of $-10^{-17}$ produced by rounding counts as negative and triggers another pivot. Phase 2 uses the trait `ApproximatelyZero` in two places: to decide whether $w^\ast$ is zero, and to recognise unit columns. For `Double` the threshold is $|x| < 10^{-15}$, an absolute bound.

Rounding errors in a pivot are relative to the size of the entries involved. One update $t_{ij} - t_{is}\, t_{rj}$ in floating point satisfies

$$
\operatorname{fl}\bigl(t_{ij} - t_{is}\, t_{rj}\bigr) = \bigl(t_{ij} - t_{is}\, t_{rj}(1 + \delta_1)\bigr)(1 + \delta_2), \qquad |\delta_1|, |\delta_2| \le u = 2^{-53} \approx 1.11 \times 10^{-16},
$$

so its absolute error is bounded by about $u\,(|t_{ij}| + 2|t_{is}\, t_{rj}|)$. After $k$ pivots on entries of magnitude around $M$, the error in $w^\ast$ is of order $k\,u\,M$. The threshold $10^{-15} \approx 9u$ is therefore appropriate for well-scaled programs with entries near $1$ and few pivots. The tests show residuals such as $w^\ast = -4.44 \times 10^{-16} = -4u$. For coefficients in the thousands, the residual can exceed the threshold and a feasible program is reported as infeasible. A relative tolerance scaled by the size of $b$ would avoid this, but it is not implemented.

## Correctness and invariants

The solver maintains these invariants between pivots:

1. **Canonical form.** Every basic column of the constraint rows is a unit vector, and row 0 is zero in every basic column. `Lp::pivot` preserves this by construction, `Lp::phase_1` establishes it for the artificial basis, and `Lp::phase_2` re-establishes it after replacing row 0.
2. **Primal feasibility.** The right-hand sides $\bar b$ are non-negative. `to_standard` makes $b \ge 0$, and the ratio test keeps it, as derived above.
3. **Objective in row 0.** The last entry of row 0 is $-z_B$.

Under these invariants, the stopping tests are correct as derived above: no negative reduced cost means optimal, and a negative reduced cost with a non-positive column means unbounded.

The implementation has known defects that break these guarantees in specific cases. They are listed here so that users can avoid them; the code is unchanged.

- **Objective row alignment.** `Lp` builds row 0 with `Obj_func::to_vector`, which takes the stored coefficients in the order of the variable names and skips zero coefficients. Row 0 then disagrees with the column order whenever an objective coefficient is zero or the variables are not declared in name order, and the solver optimises a permuted objective. For example, minimising $x_2$ subject to $x_1 \ge 1$, $x_2 \ge 2$ returns $1$ instead of $2$.
- **Basis recognition.** Phase 2 recognises basic variables as unit columns and takes the first such column in each row. When two columns are equal unit vectors, the reported solution can name the wrong variable even though the objective value is right.
- **Degenerate artificial variables.** If an artificial variable remains basic at value zero after phase 1, phase 2 drops its column without pivoting it out, and that row has no basic column during phase 2.
- **Artificial index.** `Lp::phase_1` receives `0` as the artificial column of a row that has none, which it cannot distinguish from column 0. If the phase 1 objective coefficient of column 0 happens to be $1$ at that moment, a row is subtracted from row 0 that should not be.

## Alternatives rejected

- **Big-M method.** Rejected for the numeric reasons given under "Two phases with artificial variables".
- **Bland's rule.** It guarantees termination, but it often needs many more pivots than Dantzig's rule on non-degenerate programs. The package keeps Dantzig's rule and bounds the number of iterations instead.
- **Revised simplex and interior-point methods.** They scale better to large sparse programs, but they hide the tableau, which the package exposes on purpose.
- **Enforcing variable bounds by substitution.** Bounds $l \le x \le u$ can be reduced to the standard form by $x = l + x'$ and an extra constraint $x' \le u - l$. The package stores bounds for display only and leaves such constraints to the user.

## Boundaries

The package deliberately does not:

- return errors as values. Infeasible and unbounded programs, a zero pivot and invalid arguments abort the program;
- enforce variable bounds other than $x \ge 0$;
- prevent cycling beyond the iteration limit of 1000 per simplex run;
- exploit sparsity, warm starts or a factorised basis;
- compute dual values or sensitivity ranges, although the vector $y = (A_B^{-1})^\top c_B$ of the final basis is implicit in the tableau;
- solve integer, mixed-integer or nonlinear programs.
