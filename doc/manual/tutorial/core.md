# core tutorial

This tutorial shows you how to write a linear program, bring it into standard form and solve it with the two-phase simplex method of linear-program. It starts with a two-variable production problem and ends with driving the simplex method by hand on a tableau. The mathematics behind each step is in the [design notes](../design/core.md).

| I want to | Use |
| --- | --- |
| declare decision variables | `Variable::new(name, lower, upper)`; only $x \ge 0$ is enforced |
| state the objective | `Obj_func::from_array("max" or "min", coefficients, vars)` |
| state the constraints | `Lp::new(objective, vars).cons_from_Array(eq_array=..., ineq_array=...)` |
| give an equality-only program as one matrix | `Lp::from_matrix(m, vars, sense)` |
| solve it | `lp.to_standard().two_stage()`, negating the value for `max` |
| see $A$, $b$ and $c$ of the standard form | `get_coeff_matrix`, `get_b_vector`, `get_objfunc_vector` |
| follow the simplex method step by step | `Lp::pivot` and `Lp::simplex_iteration` on a tableau |
| trust a result | substitute it into the constraints, as in [check the result yourself](#check-the-result-yourself) |

## Quick start

The module is named `linear-program`, without the `Luna-Flow/` namespace, and is not published on mooncakes under the Luna-Flow organisation yet. Use it from a local checkout: add the checkout, together with checkouts of its dependencies [luna-generic](https://lunaflow.cn/en/luna-generic/) and [linear-algebra](https://lunaflow.cn/en/linear-algebra/), to the `members` of your `moon.work`, and list it in the `import` block of your `moon.mod`:

```moonbit nocheck
import {
  "linear-program@0.1.0",
  "Luna-Flow/linear-algebra@0.4.7",
}
```

Then import the package in your `moon.pkg`:

```moonbit nocheck
import {
  "linear-program" @lp,
  "Luna-Flow/linear-algebra/mutable" @la,
  "moonbitlang/core/double",
}
```

The smallest useful program maximises $3x_1 + 4x_2$ subject to $2x_1 + x_2 \le 12$, $x_1 + 3x_2 \le 10$ and $x_1, x_2 \ge 0$:

```moonbit
using @lp {type Variable, type Poly, type Obj_func, type Lp}

test "quick start" {
  let x = [Variable::new("x1", 0.0, 100.0), Variable::new("x2", 0.0, 100.0)]
  let lp : Lp[Double] = Lp::new(Obj_func::from_array("max", [3.0, 4.0], x), x)
    .cons_from_Array(ineq_array=[([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)])
  let (solution, value) = lp.to_standard().two_stage()
  debug_inspect(solution, content="[5.199999999999999, 1.6000000000000005, 0, 0]")
  inspect(-value, content="22")
}
```

The optimum is $x_1 = 5.2$, $x_2 = 1.6$ with value $22$, up to rounding. The solution has four entries because `to_standard` adds one slack variable per inequality, and the value is negated because the standard form minimises $-3x_1 - 4x_2$.

## Everyday tasks

### Write a program and read it back

Variables carry a name and bounds; the objective carries a sense and coefficients; constraints are rows of coefficients. `Show` prints the program in the usual notation:

```moonbit
fn nonneg(names : Array[String]) -> Array[Variable] {
  names.map(n => Variable::new(n, 0.0, @double.max_value))
}

test "write a program" {
  let x = nonneg(["x1", "x2", "x3"])
  let lp : Lp[Double] = Lp::new(Obj_func::from_array("max", [1.0, 2.0, 3.0], x), x)
    .cons_from_Array(
      eq_array=[([2.0, 2.0, 3.0], 100.0)],
      ineq_array=[([2.5, 0.0, 4.7], ">=", 0.0), ([-1.7, 2.5, 12.0], "<=", 0.0)],
    )
  inspect(
    lp,
    content=(
      #|max  x1 + 2x2 + 3x3
      #|s.t. 2x1 + 2x2 + 3x3 = 100
      #|     2.5x1 + 4.7x3 >= 0
      #|    -1.7x1 + 2.5x2 + 12x3 <= 0
      #|     x1 : [0, 1.7976931348623157e+308] x2 : [0, 1.7976931348623157e+308] x3 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
}
```

An equality row is `(coefficients, b)`; an inequality row is `(coefficients, relation, b)` with the relation written exactly as `">="` or `"<="`. The `nonneg` helper is used by the remaining examples.

### Bring a program into standard form

The solver works on $\min c^\top x$ subject to $Ax = b$, $b \ge 0$, $x \ge 0$. `to_standard` produces it, and the accessors return $c$, $A$ and $b$:

```moonbit
test "standard form" {
  let x = nonneg(["x1", "x2"])
  let lp : Lp[Double] = Lp::new(Obj_func::from_array("min", [3.0, 4.0], x), x)
    .cons_from_Array(ineq_array=[([2.0, 1.0], ">=", 12.0), ([1.0, 3.0], ">=", 10.0)])
  let s = lp.to_standard()
  inspect(
    s,
    content=(
      #|min  3x1 + 4x2
      #|s.t. 2x1 + x2 + -1y1 = 12
      #|     x1 + 3x2 + -1y2 = 10
      #|      x1 : [0, 1.7976931348623157e+308] x2 : [0, 1.7976931348623157e+308] y1 : [0, 1.7976931348623157e+308] y2 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
  debug_inspect(s.get_objfunc_vector(), content="[3, 4, 0, 0]")
  debug_inspect(s.get_b_vector(), content="[12, 10]")
}
```

Each `>=` row received a surplus variable with coefficient $-1$, so $2x_1 + x_2 \ge 12$ became $2x_1 + x_2 - y_1 = 12$ with $y_1 \ge 0$.

### Solve a minimisation problem

A minimisation problem needs no sign change: the returned value is the minimum.

```moonbit
test "minimise" {
  let x = nonneg(["x1", "x2"])
  let lp : Lp[Double] = Lp::new(Obj_func::from_array("min", [3.0, 4.0], x), x)
    .cons_from_Array(ineq_array=[([2.0, 1.0], ">=", 12.0), ([1.0, 3.0], ">=", 10.0)])
  let (solution, value) = lp.to_standard().two_stage()
  debug_inspect(solution, content="[5.199999999999999, 1.6000000000000005, 0, 0]")
  inspect(value, content="22")
}
```

No slack column is a unit column here, so phase 1 adds two artificial variables, drives them to zero, and phase 2 then minimises the real objective from the feasible point phase 1 found.

### Write a program with equality constraints as a matrix

When every constraint is an equality, the whole program fits in one matrix: row 0 holds the objective coefficients and every further row holds one constraint $[a_i \mid b_i]$. This program minimises $-x_1 - 2x_2 - 3x_3$ subject to $x_1 + 2x_2 + 3x_3 = 10$ and $2x_1 + x_2 + x_3 = 8$:

```moonbit
test "from a matrix" {
  let x = nonneg(["x1", "x2", "x3"])
  let m : @la.Matrix[Double] = @la.Matrix::from_2d_array([
    [-1.0, -2.0, -3.0, 0.0],
    [1.0, 2.0, 3.0, 10.0],
    [2.0, 1.0, 1.0, 8.0],
  ])
  let lp = Lp::from_matrix(m, x, "min")
  inspect(
    lp,
    content=(
      #|min  -1x1 + -2x2 + -3x3
      #|s.t. x1 + 2x2 + 3x3 = 10
      #|     2x1 + x2 + x3 = 8
      #|      x1 : [0, 1.7976931348623157e+308] x2 : [0, 1.7976931348623157e+308] x3 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
  let (solution, value) = lp.to_standard().two_stage()
  debug_inspect(solution, content="[1.9999999999999991, 4.000000000000001, 0]")
  inspect(value, content="-10")
}
```

The optimum is $x = (2, 4, 0)$ with value $-10$. The last entry of row 0 is ignored by `from_matrix`.

### Build expressions term by term

`Poly` and `Obj_func` can also be built one term at a time, which is convenient when coefficients come from data:

```moonbit
test "term by term" {
  let x = nonneg(["x1", "x2"])
  let p : Poly[Double] = Poly::new()
  p.add_term_inplace(x[0], 3.0)
  p.add_term_inplace(x[1], 4.0)
  p.add_term_inplace(x[0], 1.0)
  let obj = Obj_func::new("max").set_poly(p)
  inspect(obj, content="max  4x1 + 4x2")
  let lp = Lp::new(obj, x).cons_from_Array(ineq_array=[([1.0, 1.0], "<=", 5.0)])
  let (_, value) = lp.to_standard().two_stage()
  inspect(-value, content="20")
}
```

`add_term_inplace` adds to an existing coefficient, so `x1` ends with $3 + 1 = 4$.

## Going further

### Drive the simplex method by hand

The steps of `two_stage` are public. When a program is already in canonical form, for example because every constraint is `<=` with $b \ge 0$ and the slack columns form an identity, you can write the tableau yourself and pivot on it. Row 0 holds the reduced costs and $-z$:

```moonbit
test "pivot by hand" {
  // max 3x1 + 4x2  ==  min -3x1 - 4x2, slack variables y1, y2 basic
  let t : @la.Matrix[Double] = @la.Matrix::from_2d_array([
    [-3.0, -4.0, 0.0, 0.0, 0.0],
    [2.0, 1.0, 1.0, 0.0, 12.0],
    [1.0, 3.0, 0.0, 1.0, 10.0],
  ])
  // x2 has the most negative reduced cost; the ratios are 12/1 and 10/3, so row 2 leaves
  Lp::pivot(t, 2, 1)
  inspect(
    t,
    content=(
      #||-1.6666666666666667, 0, 0, 1.3333333333333333, 13.333333333333334|
      #||1.6666666666666667, 0, 1, -0.3333333333333333, 8.666666666666666|
      #||0.3333333333333333, 1, 0, 0.3333333333333333, 3.3333333333333335|
    ),
  )
  // finish with Dantzig's rule
  Lp::simplex_iteration(t)
  inspect(t[0][4], content="22")
}
```

After the first pivot the objective has improved from $0$ to $40/3$; the remaining negative reduced cost of $x_1$ says that one more pivot improves it further, to $22$. Pass `debug=true` to `simplex_iteration` to print every pivot.

### Coefficient types

Every function is generic in the coefficient type `V`, and the modelling functions (`Variable`, `Poly`, `Obj_func`, `Constraint`, `Lp::to_standard`) work with any type that has the luna-generic traits they ask for. The solver also needs `ApproximatelyZero`, which is read-only outside the package: only `Int` and `Double` implement it, and you cannot add your own exact number type. Since integer division truncates, use `Double` for `two_stage`.

### Check the result yourself

`two_stage` aborts on infeasible and unbounded programs instead of returning an error, so validate the input before calling it when the program comes from user data. After solving, substitute the solution back into the constraints of the standard form to confirm feasibility:

```moonbit
test "check feasibility" {
  let x = nonneg(["x1", "x2"])
  let s : Lp[Double] = Lp::new(Obj_func::from_array("max", [3.0, 4.0], x), x)
    .cons_from_Array(ineq_array=[([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)])
    .to_standard()
  let (solution, _) = s.two_stage()
  let a = s.get_coeff_matrix()
  let b = s.get_b_vector()
  for i in 0..<b.length() {
    let mut lhs = 0.0
    for j in 0..<solution.length() {
      lhs = lhs + a[i][j] * solution[j]
    }
    assert_true((lhs - b[i]).abs() < 1.0e-9)
  }
}
```

## Common pitfalls

- **The returned value belongs to the standard form.** `to_standard` turns every program into a minimisation, so for a maximisation problem negate the value returned by `two_stage`.
- **The solution includes slack variables.** Its length is the number of variables of the standard form; your own variables come first, in declaration order.
- **Objective coefficients must line up.** Because of a known defect, the objective row is filled from the non-zero coefficients in the order of the variable names. Give every variable a non-zero objective coefficient and declare variables in name order (`x1`, `x2`, ..., not `x2` before `x10`), or the solver optimises a different objective.
- **Bounds are not enforced.** `Variable::new("x", 0.0, 100.0)` stores the bound $100$, but the solver only assumes $x \ge 0$. Add an explicit constraint `([1.0, ...], "<=", 100.0)` for an upper bound.
- **Infeasible and unbounded programs abort.** There is no `Result` to inspect.
- **Use `Double` coefficients.** `Int` satisfies the trait bounds, but integer division truncates, so pivoting on `Int` gives wrong results.
- **Tolerance is absolute.** Phase 2 treats $|x| < 10^{-15}$ as zero. For programs with large coefficients, rounding errors can exceed this threshold and an infeasibility can be reported for a feasible program; rescale the rows so that coefficients are of moderate size.
- **Do not name variables `y1`, `y2`, ...** `to_standard` uses these names for slack variables, and variables are identified by name.
- **Some feasible bounded programs fail.** When phase 1 leaves an artificial variable in the basis, or when one of your own variables already has a unit column, the solver can return a point that violates a constraint or abort with `Problem is unbounded`. The warning under [`Lp::two_stage`](../api/core.md#lptwo_stage) gives small examples; equality constraints with right-hand side $0$ are a typical trigger. Check every solution against the constraints.
- **Degenerate programs can cycle.** A run that hits the iteration limit prints a message and returns a non-optimal result without an error.

## Next steps

- The [API reference](../api/core.md) documents every type and function, including `Lp::phase_1` and `Lp::phase_2`.
- The [design notes](../design/core.md) derive the standard form, the optimality and unboundedness tests and the two phases.
- [linear-algebra](https://lunaflow.cn/en/linear-algebra/) provides the `Matrix` type used for tableaux, and [luna-generic](https://lunaflow.cn/en/luna-generic/) the traits that bound the coefficient type.
