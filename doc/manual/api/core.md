# core API

The package at `src` is the whole public surface of linear-program. Its interface file is [`src/linear-program.mbti`](../../../src/linear-program.mbti). The coefficient type `V` is generic; the solver needs the traits listed in each signature, and `Double` satisfies all of them.

Matrices in this package are `@mutable.Matrix[V]` from the `mutable` package of [linear-algebra](https://luna-flow.github.io/en/linear-algebra/). Row 0 of a program matrix holds the objective coefficients, the other rows hold one equality constraint each, and the last column holds the right-hand sides.

## Variables

### `Variable`

`Variable` is a named decision variable with a lower and an upper bound.

```mbti
type Variable
fn Variable::new(String, Double, Double) -> Self
fn Variable::show_all(Self) -> String
impl @luna-generic.One for Variable
impl Compare for Variable
impl Eq for Variable
impl Show for Variable
```

`Variable::new(name, low, up)` creates a variable. Two variables are equal when their names are equal, and they are ordered by name. `Show` prints the name; `show_all` prints the name with its bounds, for example `x1 : [0, 100]`. `One::one()` is the unnamed variable that `Poly::from_var_array` uses for a constant term.

The bounds are stored and printed, but the solver does not read them: every variable is treated as non-negative. `Lp::to_standard` names the variables it adds `y1`, `y2`, ..., so do not use these names for your own variables.

## Linear expressions

### `Poly`

`Poly[V]` is a linear expression: a map from variables to non-zero coefficients, kept in the order of the variable names.

```mbti
type Poly[V]
fn[V] Poly::new() -> Self[V]
fn[V : Eq + @luna-generic.Semiring] Poly::from_var_array(Array[V], Array[Variable]) -> Self[V]
fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero] Poly::add_term_inplace(Self[V], Variable, V) -> Unit
fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero] Poly::copy(Self[V]) -> Self[V]
fn[V] Poly::to_array(Self[V]) -> Array[V]
fn[V : @luna-generic.Zero] Poly::to_vector(Self[V], Array[Variable]) -> Array[V]
impl[V : Eq] Eq for Poly[V]
impl[V : Eq + @luna-generic.Semiring + @luna-generic.Zero + Neg] Neg for Poly[V]
impl[V : Eq + Show + @luna-generic.Semiring + @luna-generic.One] Show for Poly[V]
```

| Function | Meaning |
| --- | --- |
| `Poly::new()` | The empty expression. |
| `Poly::from_var_array(coeffs, vars)` | Pairs `coeffs[i]` with `vars[i]` and skips zero coefficients. A coefficient beyond the last variable becomes the constant term. |
| `add_term_inplace(var, coeff)` | Adds `coeff` to the coefficient of `var` and removes the term when the sum is zero. |
| `copy()` | A copy that does not share storage with the original. |
| `to_array()` | The stored coefficients in the order of the variable names. |
| `to_vector(vars)` | One coefficient per entry of `vars`, with zero for a variable that does not occur. |

`Show` prints an expression such as `3.5x1 + 1.5x2 + -2x3`, and `-poly` negates every coefficient.

## Objective functions

### `Obj_func`

`Obj_func[V]` is an objective: a linear expression with the sense minimise or maximise.

```mbti
type Obj_func[V]
fn[V] Obj_func::new(String) -> Self[V]
fn[V : Eq + @luna-generic.Semiring] Obj_func::from_array(String, Array[V], Array[Variable]) -> Self[V]
fn[V] Obj_func::set_poly(Self[V], Poly[V]) -> Self[V]
fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero] Obj_func::add_term_inplace(Self[V], Variable, V) -> Unit
fn[V] Obj_func::judge_max(Self[V]) -> Bool
fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero + Neg] Obj_func::to_min(Self[V]) -> Self[V]
fn[V : @luna-generic.Zero] Obj_func::to_vector(Self[V], Int) -> Array[V]
impl[V : Eq + Show + @luna-generic.Semiring] Show for Obj_func[V]
```

`Obj_func::new(sense)` creates an objective with an empty expression. The sense is `"min"`, `"Min"`, `"MIN"`, `"minimize"` or `"Minimize"` for minimisation and `"max"`, `"Max"`, `"MAX"`, `"maximize"` or `"Maximize"` for maximisation; any other string aborts. `Obj_func::from_array(sense, coeffs, vars)` also sets the expression from coefficients, like `Poly::from_var_array`.

| Function | Meaning |
| --- | --- |
| `set_poly(poly)` | A new objective with the same sense and the expression `poly`. |
| `add_term_inplace(var, coeff)` | Adds a term to the expression in place. |
| `judge_max()` | `true` for a maximisation objective. |
| `to_min()` | The equivalent minimisation objective; a maximisation objective is negated. |
| `to_vector(n)` | The coefficients of `to_array`, padded with zeros to length `n + 1`, the width of a tableau row. |

`Show` prints the sense and the expression, for example `max  3.5x1 + 1.5x2 + -2x3`.

## Constraints

### `Constraint`

`Constraint[V]` is the constraint set of a program: equalities `poly = b` and inequalities `poly <= b` or `poly >= b`.

```mbti
type Constraint[V]
fn[V] Constraint::new() -> Self[V]
fn[V : Eq + @luna-generic.Semiring] Constraint::from_array(eq_array~ : Array[(Array[V], V)] = .., ineq_array~ : Array[(Array[V], String, V)] = .., Array[Variable]) -> Self[V]
fn[V] Constraint::add_eqpoly(Self[V], Poly[V], V) -> Unit
fn[V] Constraint::add_ineqpoly(Self[V], Poly[V], String, V) -> Unit
fn[V] Constraint::change_eqpoly(Self[V], Int, Poly[V], V) -> Unit
fn[V] Constraint::change_ineqpoly(Self[V], Int, Poly[V], String, V) -> Unit
fn[V : @luna-generic.Zero] Constraint::to_matrix(Self[V], Array[Variable]) -> Array[Array[V]]
impl[V : Show + Eq + @luna-generic.Semiring] Show for Constraint[V]
```

`Constraint::from_array(eq_array~, ineq_array~, vars)` builds the set from rows of coefficients. An equality row is `(coeffs, b)`; an inequality row is `(coeffs, relation, b)` where `relation` is `">="` or `"<="`. Any other relation aborts.

| Function | Meaning |
| --- | --- |
| `Constraint::new()` | The empty set. |
| `add_eqpoly(poly, b)` | Appends `poly = b`. |
| `add_ineqpoly(poly, relation, b)` | Appends `poly relation b`; `relation` should be `">="` or `"<="`. |
| `change_eqpoly(i, poly, b)` | Replaces the equality at the 1-based position `i`; aborts when `i` is out of range. |
| `change_ineqpoly(i, poly, relation, b)` | Replaces the inequality at the 1-based position `i`; aborts when `i` is out of range. |
| `to_matrix(vars)` | One row `[coefficients..., b]` per equality, with columns in the order of `vars`. Inequalities are left out, so call it on a program in standard form. |

`Show` prints the set after `s.t.`, one constraint per line.

## Programs

### `Lp`

`Lp[V]` is a linear program: its variables, objective, constraints and the matrix built from them.

```mbti
type Lp[V]
fn[V : @luna-generic.Zero] Lp::new(Obj_func[V], Array[Variable]) -> Self[V]
fn[V : Eq + @luna-generic.Semiring] Lp::cons_from_Array(Self[V], eq_array~ : Array[(Array[V], V)] = .., ineq_array~ : Array[(Array[V], String, V)] = ..) -> Self[V]
fn[V : Compare + @luna-generic.Semiring + @luna-generic.Zero] Lp::reset_obj_byarray(Self[V], Array[V]) -> Self[V]
fn[V : Eq + @luna-generic.Semiring] Lp::from_matrix(@mutable.Matrix[V], Array[Variable], String) -> Self[V]
fn[V : Eq + @luna-generic.Semiring + Compare + Neg + @luna-generic.Zero] Lp::to_standard(Self[V]) -> Self[V]
fn[V] Lp::get_coeff_matrix(Self[V]) -> @mutable.Matrix[V]
fn[V] Lp::get_objfunc_vector(Self[V]) -> Array[V]
fn[V] Lp::get_b_vector(Self[V]) -> Array[V]
impl[V : Show + Eq + @luna-generic.Semiring] Show for Lp[V]
```

Every function returns a new program and leaves its argument unchanged.

| Function | Meaning |
| --- | --- |
| `Lp::new(obj, vars)` | A program with objective `obj`, variables `vars` and no constraints. |
| `cons_from_Array(eq_array~, ineq_array~)` | The program with its constraints replaced, as in `Constraint::from_array`. |
| `reset_obj_byarray(coeffs)` | The program with new objective coefficients and the same sense. |
| `Lp::from_matrix(matrix, vars, sense)` | A program from a matrix: row 0 without its last entry gives the objective, every other row `[a..., b]` gives the equality `a · x = b`. |
| `to_standard()` | The equivalent program in standard form: a minimisation objective, equality constraints only, and non-negative right-hand sides. Each inequality receives a slack or surplus variable `y1`, `y2`, ... appended to the variables. |
| `get_coeff_matrix()` | The constraint coefficients $A$ of the program matrix. |
| `get_objfunc_vector()` | Row 0 of the program matrix without its last entry. |
| `get_b_vector()` | The right-hand sides $b$ of the program matrix. |

The program matrix is built from the objective and the equality constraints, so the three accessors describe a program with inequalities only after `to_standard`. `Show` prints the objective, the constraints and every variable with its bounds.

## Solving

### `Lp::two_stage`

`two_stage` solves a program in standard form with the two-phase simplex method.

```mbti
fn[V : Eq + @luna-generic.Zero + @luna-generic.One + Compare + Mul + Div + Sub + ApproximatelyZero + Show + Neg] Lp::two_stage(Self[V]) -> (Array[V], V)
```

Call it on the result of `to_standard`. It returns the values of all variables of the standard form, including the added `y` variables, and the optimal value of the standard form, which is always a minimisation. For a program that maximises, the maximum is the negation of the returned value.

The solver aborts when the program is infeasible (phase 1 ends with a non-zero artificial objective) and when it is unbounded. Each simplex run stops after 1000 iterations and prints a message if it has not converged.

### `Lp::pivot`

`pivot` performs one Gauss–Jordan pivot of a tableau in place.

```mbti
fn[V : @luna-generic.Zero + Compare + Div + Mul + Sub] Lp::pivot(@mutable.Matrix[V], Int, Int) -> Unit
```

`Lp::pivot(matrix, row, col)` divides row `row` by the pivot element and eliminates column `col` from every other row. It aborts when the position lies outside the matrix or the pivot element is zero.

### `Lp::simplex_iteration`

`simplex_iteration` runs the simplex method on a tableau in place.

```mbti
fn[V : @luna-generic.Zero + Compare + Sub + Mul + Div + Show] Lp::simplex_iteration(@mutable.Matrix[V], max_iterations~ : Int = .., debug~ : Bool = ..) -> Unit
```

Row 0 of the tableau is the objective row and the last column holds the right-hand sides. Each iteration enters the column with the most negative objective coefficient and leaves the row chosen by the minimum ratio test. The run stops when no objective coefficient is negative or after `max_iterations` iterations (1000 by default), and aborts when the program is unbounded. With `debug=true` it prints every pivot and the tableau after it.

### `Lp::phase_1` and `Lp::phase_2`

`phase_1` and `phase_2` are the two halves of `two_stage`.

```mbti
fn[V : @luna-generic.Zero + @luna-generic.One + Compare + Sub + Compare + Div + Mul + Show] Lp::phase_1(@mutable.Matrix[V], Array[Int]) -> @mutable.Matrix[V]
fn[V : @luna-generic.Zero + @luna-generic.One + Eq + ApproximatelyZero + Div + Sub + Mul + Show + Compare] Lp::phase_2(Array[Variable], Array[V], @mutable.Matrix[V]) -> (Array[V], V)
```

`Lp::phase_1(tableau, artificial_index)` takes a tableau extended with artificial variables, where `artificial_index[i]` is the column of the artificial variable of constraint `i`. It eliminates the artificial columns from the objective row, runs `simplex_iteration` and returns the tableau.

`Lp::phase_2(vars, objective, tableau)` drops the artificial columns of the phase 1 tableau, restores the original `objective`, runs `simplex_iteration` again and returns the basic solution with the value in the objective row. It aborts when phase 1 did not reach zero, because the program then has no feasible solution.

## Numeric tolerance

### `ApproximatelyZero`

`ApproximatelyZero` decides whether a value is zero for the purposes of the solver.

```mbti
pub trait ApproximatelyZero {
  is_zero_eps(Self) -> Bool
}
impl ApproximatelyZero for Int
impl ApproximatelyZero for Double
fn[V : ApproximatelyZero] double_equal_to_zero(V) -> Bool
```

An `Int` is zero only when it equals `0`; a `Double` is zero when its absolute value is below $10^{-15}$. `double_equal_to_zero(x)` calls `is_zero_eps(x)`.
