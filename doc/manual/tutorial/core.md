# core tutorial

This tutorial solves two small linear programs: one written with coefficient arrays and one written as a matrix. The examples are taken from the tests in [`src/linequest.mbt`](../../../src/linequest.mbt) and run inside the package; from another package, prefix the names with the alias under which you import linear-program.

## Defining a program from arrays

A program is defined in five steps:

1. define the variables;
2. define the objective function;
3. define the equality constraints;
4. define the inequality constraints;
5. combine them into a linear program.

```moonbit
let arr = [
  Variable::new("x1", 0.0, 100.0),
  Variable::new("x2", 0.0, 100.0),
  Variable::new("x3", 0.0, 100.0),
]
let obj_func = Obj_func::from_array("max", [1.0, 2.0, 3.0], arr)
let eqarr = [([2.0, 2.0, 3.0], 100.0)]
let ineqarr = [([2.5, 0.0, 4.7], ">=", 0.0), ([-1.7, 2.5, 12.0], "<=", 0.0)]
let lp = Lp::new(obj_func, arr).cons_from_Array(
  eq_array=eqarr,
  ineq_array=ineqarr,
)
```

Each equality row is `(coefficients, b)` and each inequality row is `(coefficients, relation, b)` with `">="` or `"<="` as the relation.

## Solving a maximisation problem

Maximise $3x_1 + 4x_2$ subject to $2x_1 + x_2 \le 12$ and $x_1 + 3x_2 \le 10$:

```moonbit
let vars = [
  Variable::new("x1", 0.0, @double.max_value),
  Variable::new("x2", 0.0, @double.max_value),
]
let obj_func = Obj_func::from_array("max", [3.0, 4.0], vars)
let ineq = [([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)]
let lp = Lp::new(obj_func, vars)
  .cons_from_Array(ineq_array=ineq)
  .to_standard()
let res = lp.two_stage()
inspect(res.0, content="[5.199999999999999, 1.6000000000000005, 0, 0]")
inspect(-res.1, content="22")
```

`to_standard` adds the slack variables `y1` and `y2`, so the solution has four entries: $x_1 = 5.2$, $x_2 = 1.6$ and both slacks zero. The standard form minimises $-3x_1 - 4x_2$, so the maximum of the original objective is the negated value, $22$.

## Defining a program as a matrix

When every constraint is an equality, the whole program fits in one matrix. Row 0 holds the objective coefficients and every other row holds the coefficients and the right-hand side of one constraint. This program minimises $-x_1 - 2x_2 - 3x_3$ subject to $x_1 + 2x_2 + 3x_3 = 10$ and $2x_1 + x_2 + x_3 = 8$:

```moonbit
let vars = [
  Variable::new("x1", 0.0, @double.max_value),
  Variable::new("x2", 0.0, @double.max_value),
  Variable::new("x3", 0.0, @double.max_value),
]
let matrix : Matrix[Double] = Matrix::from_2d_array([
  [-1, -2, -3, 0],
  [1, 2, 3, 10],
  [2, 1, 1, 8],
])
let lp = Lp::from_matrix(matrix, vars, "min").to_standard()
let res = lp.two_stage()
inspect(res.0, content="[1.9999999999999991, 4.000000000000001, 0]")
inspect(res.1, content="-10")
```

The result is the pair of the variable values and the optimal value: $x = (2, 4, 0)$ with minimum $-10$, up to rounding.

## Next steps

The [API reference](../api/core.md) lists every function used here and the lower-level steps `Lp::phase_1`, `Lp::phase_2` and `Lp::simplex_iteration`. The [design notes](../design/core.md) explain the standard form and the two phases.
