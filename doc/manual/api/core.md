# core API

The package at `src` is the whole public surface of linear-program. Its interface file is [`src/pkg.generated.mbti`](../../../src/pkg.generated.mbti). The package path is `linear-program`: the module name has no `Luna-Flow/` namespace yet, so other packages import it as `"linear-program"`.

The coefficient type `V` is generic. Each function states the traits it needs; `Double` satisfies all of them, and it is the only type the solver is tested with. Matrices are `@mutable.Matrix[V]` from the `mutable` package of [linear-algebra](https://lunaflow.cn/en/linear-algebra/). A *program matrix* or *tableau* stores the objective in row 0 and one equality constraint in each further row; its last column holds the right-hand sides.

The examples on this page are tests in a package with this `moon.pkg`:

```text
import {
  "linear-program" @lp,
  "Luna-Flow/linear-algebra/mutable" @la,
  "moonbitlang/core/double",
}
```

and they share these declarations:

```moonbit
using @lp {type Variable, type Poly, type Obj_func, type Constraint, type Lp}

fn nonneg(names : Array[String]) -> Array[Variable] {
  names.map(n => Variable::new(n, 0.0, @double.max_value))
}
```

## Variables

### `Variable`

`Variable` is a named decision variable with a lower and an upper bound.

```mbti
type Variable
pub impl @luna-generic.One for Variable
pub impl Compare for Variable
pub impl Eq for Variable
pub impl Show for Variable
```

`Variable` is an abstract type: you create values with `Variable::new` and cannot read the fields directly. Two variables are equal when their names are equal, whatever their bounds, and they are ordered by name. The bounds are stored and printed, but the solver does not read them: every variable of a program is treated as non-negative.

### `Variable::new`

`Variable::new` creates a variable from its name, lower bound and upper bound.

```mbti
pub fn Variable::new(String, Double, Double) -> Self
```

Use `@double.max_value` for an upper bound that is not meant to restrict anything. `Lp::to_standard` names the variables it adds `y1`, `y2`, ..., so do not use these names for your own variables.

### `Variable::show_all`

`show_all` prints the name of a variable together with its bounds.

```mbti
pub fn Variable::show_all(Self) -> String
```

```moonbit
test "variables" {
  let x = Variable::new("x1", 0.0, 100.0)
  inspect(x, content="x1")
  inspect(x.show_all(), content="x1 : [0, 100]")
  assert_true(x == Variable::new("x1", -5.0, 5.0))
  assert_true(x < Variable::new("x2", 0.0, 1.0))
}
```

### `Variable::to_string`, `Variable::equal`, `Variable::compare`

These are the `Show`, `Eq` and `Compare` methods, promoted to methods of `Variable`.

```mbti
pub fn Variable::to_string(Self) -> String
pub fn Variable::equal(Self, Self) -> Bool
pub fn Variable::compare(Self, Self) -> Int
```

`to_string` returns the name. `equal` and `compare` look at the name only; `compare` is the lexicographic order of the names, so `"x10"` comes before `"x2"`. Prefer `"\{x}"`, `==` and `<` in new code.

### `Variable::one`

`Variable::one` is the unnamed variable that stands for the constant term of a linear expression.

```mbti
pub fn Variable::one() -> Self
```

It is the `One` method of luna-generic promoted to a method. Its name is empty and its bounds are `@double.min_value` and `@double.max_value`. `Poly::from_var_array` attaches a coefficient that has no matching variable to it.

## Linear expressions

### `Poly`

`Poly[V]` is a linear expression: a map from variables to non-zero coefficients, kept in the order of the variable names.

```mbti
type Poly[V] derive(Eq)
pub impl[V : Eq + @luna-generic.Semiring + @luna-generic.Zero + Neg] Neg for Poly[V]
pub impl[V : Eq + Show + @luna-generic.Semiring + @luna-generic.One] Show for Poly[V]
```

A `Poly` is mutable: `add_term_inplace` changes it, and every value that shares it sees the change. Use `copy` when you need an independent expression. Two expressions are equal when they have the same variables with equal coefficients.

### `Poly::new`, `Poly::from_var_array`

`Poly::new` creates the empty expression; `Poly::from_var_array` creates one from coefficients.

```mbti
pub fn[V] Poly::new() -> Self[V]
pub fn[V : Eq + @luna-generic.Semiring] Poly::from_var_array(Array[V], Array[Variable]) -> Self[V]
```

`Poly::from_var_array(coeffs, vars)` pairs `coeffs[i]` with `vars[i]` and skips zero coefficients. A coefficient at a position beyond the last variable is attached to `Variable::one()`, the constant term; when there are several such coefficients, the last one wins.

### `Poly::add_term_inplace`

`add_term_inplace` adds a multiple of a variable to an expression in place.

```mbti
pub fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero] Poly::add_term_inplace(Self[V], Variable, V) -> Unit
```

`p.add_term_inplace(x, c)` adds `c` to the coefficient of `x`. Adding zero does nothing, and a term whose coefficient becomes zero is removed, so no zero coefficient is ever stored.

### `Poly::copy`

`copy` returns an expression with the same terms that does not share storage with the original.

```mbti
pub fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero] Poly::copy(Self[V]) -> Self[V]
```

### `Poly::to_array`, `Poly::to_vector`

`to_array` lists the stored coefficients; `to_vector` lists one coefficient per given variable.

```mbti
pub fn[V] Poly::to_array(Self[V]) -> Array[V]
pub fn[V : @luna-generic.Zero] Poly::to_vector(Self[V], Array[Variable]) -> Array[V]
```

`to_array` returns the non-zero coefficients in the order of the variable names, without the variables. `to_vector(vars)` returns `vars.length()` coefficients in the order of `vars`, with zero for a variable that does not occur; this is the dense row used in a program matrix.

### `Poly::neg`, `Poly::equal`, `Poly::to_string`

These are the `Neg`, `Eq` and `Show` methods, promoted to methods of `Poly`.

```mbti
pub fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero + Neg] Poly::neg(Self[V]) -> Self[V]
pub fn[V : Eq] Poly::equal(Self[V], Self[V]) -> Bool
pub fn[V : Eq + Show + @luna-generic.Semiring + @luna-generic.One] Poly::to_string(Self[V]) -> String
```

`-p` negates every coefficient and returns a new expression. `Show` prints the terms in name order, joined by `" + "`, and leaves out a coefficient equal to one, for example `3.5x1 + x2 + -2x3`.

```moonbit
test "linear expressions" {
  let vars = nonneg(["x1", "x2", "x3"])
  let p : Poly[Double] = Poly::from_var_array([3.5, 0.0, -2.0], vars)
  inspect(p, content="3.5x1 + -2x3")
  p.add_term_inplace(vars[1], 1.0)
  p.add_term_inplace(vars[2], 2.0)
  inspect(p, content="3.5x1 + x2")
  inspect(-p, content="-3.5x1 + -1x2")
  debug_inspect(p.to_array(), content="[3.5, 1]")
  debug_inspect(p.to_vector(vars), content="[3.5, 1, 0]")
  assert_true(p.copy() == p)
}
```

## Objective functions

### `Obj_func`

`Obj_func[V]` is an objective: a linear expression together with the sense, minimise or maximise.

```mbti
type Obj_func[V]
pub impl[V : Eq + Show + @luna-generic.Semiring] Show for Obj_func[V]
```

`Show` prints the sense and the expression, for example `max  3x1 + 4x2`. `Obj_func::to_string` is the promoted `Show` method.

```mbti
pub fn[V : Eq + Show + @luna-generic.Semiring] Obj_func::to_string(Self[V]) -> String
```

### `Obj_func::new`, `Obj_func::from_array`

`Obj_func::new` creates an objective with an empty expression; `Obj_func::from_array` also sets the expression.

```mbti
pub fn[V] Obj_func::new(String) -> Self[V]
pub fn[V : Eq + @luna-generic.Semiring] Obj_func::from_array(String, Array[V], Array[Variable]) -> Self[V]
```

The sense is one of `"min"`, `"Min"`, `"MIN"`, `"minimize"`, `"Minimize"` for minimisation and `"max"`, `"Max"`, `"MAX"`, `"maximize"`, `"Maximize"` for maximisation. Any other string aborts. `Obj_func::from_array(sense, coeffs, vars)` builds the expression with `Poly::from_var_array`.

### `Obj_func::set_poly`, `Obj_func::add_term_inplace`

`set_poly` replaces the expression; `add_term_inplace` adds a term to it in place.

```mbti
pub fn[V] Obj_func::set_poly(Self[V], Poly[V]) -> Self[V]
pub fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero] Obj_func::add_term_inplace(Self[V], Variable, V) -> Unit
```

`set_poly(p)` returns a new objective with the same sense and the expression `p`; it does not copy `p`.

### `Obj_func::judge_max`, `Obj_func::to_min`

`judge_max` tells whether an objective maximises; `to_min` returns the equivalent minimisation objective.

```mbti
pub fn[V] Obj_func::judge_max(Self[V]) -> Bool
pub fn[V : Eq + @luna-generic.Semiring + @luna-generic.Zero + Neg] Obj_func::to_min(Self[V]) -> Self[V]
```

`to_min` returns a minimisation objective unchanged and negates the expression of a maximisation objective, because $\max c^\top x = -\min\,(-c)^\top x$.

### `Obj_func::to_vector`

`to_vector` returns the objective row of a program matrix.

```mbti
pub fn[V : @luna-generic.Zero] Obj_func::to_vector(Self[V], Int) -> Array[V]
```

`to_vector(n)` takes the coefficients of `to_array` and pads them with zeros to length `n + 1`, the width of a tableau row. Because `to_array` lists only non-zero coefficients in name order, the result lines up with the variables only when every variable has a non-zero coefficient and the variables are declared in name order. See the warning under `Lp::two_stage` below.

```moonbit
test "objectives" {
  let vars = nonneg(["x1", "x2"])
  let obj : Obj_func[Double] = Obj_func::from_array("max", [3.0, 4.0], vars)
  inspect(obj, content="max  3x1 + 4x2")
  assert_true(obj.judge_max())
  inspect(obj.to_min(), content="min  -3x1 + -4x2")
  debug_inspect(obj.to_vector(2), content="[3, 4, 0]")
}
```

## Constraints

### `Constraint`

`Constraint[V]` is the constraint set of a program: equalities `poly = b` and inequalities `poly <= b` or `poly >= b`.

```mbti
type Constraint[V]
pub impl[V : Show + Eq + @luna-generic.Semiring] Show for Constraint[V]
pub fn[V : Show + Eq + @luna-generic.Semiring] Constraint::to_string(Self[V]) -> String
```

`Show` prints the set after `s.t.`, one constraint per line, equalities first. A program receives its constraints through `Lp::cons_from_Array`; a `Constraint` value on its own is useful for building and printing constraint sets.

### `Constraint::new`, `Constraint::from_array`

`Constraint::new` creates the empty set; `Constraint::from_array` builds one from coefficient rows.

```mbti
pub fn[V] Constraint::new() -> Self[V]
pub fn[V : Eq + @luna-generic.Semiring] Constraint::from_array(eq_array? : Array[(Array[V], V)], ineq_array? : Array[(Array[V], String, V)], Array[Variable]) -> Self[V]
```

An equality row is `(coeffs, b)`; an inequality row is `(coeffs, relation, b)` where `relation` is exactly `">="` or `"<="`. Any other relation aborts. Both arrays default to empty.

### `Constraint::add_eqpoly`, `Constraint::add_ineqpoly`

`add_eqpoly` appends an equality and `add_ineqpoly` appends an inequality.

```mbti
pub fn[V] Constraint::add_eqpoly(Self[V], Poly[V], V) -> Unit
pub fn[V] Constraint::add_ineqpoly(Self[V], Poly[V], String, V) -> Unit
```

`add_ineqpoly` does not check the relation string; pass `">="` or `"<="`.

### `Constraint::change_eqpoly`, `Constraint::change_ineqpoly`

These replace the constraint at a 1-based position.

```mbti
pub fn[V] Constraint::change_eqpoly(Self[V], Int, Poly[V], V) -> Unit
pub fn[V] Constraint::change_ineqpoly(Self[V], Int, Poly[V], String, V) -> Unit
```

`change_eqpoly(i, poly, b)` replaces equality number `i`, counting from 1. Both functions abort when `i` is not positive or not below the *capacity* of the equality array, which is an implementation detail of the array.

> [!WARNING]
> The range check is unreliable. Both functions compare `i` with the capacity of the array, not its length, and `change_ineqpoly` checks the *equality* array instead of the inequality array. An index that the check lets through can still abort on the array access, and a valid inequality index can be rejected when there are fewer equalities. Only pass indices of constraints that exist.

### `Constraint::to_matrix`

`to_matrix` returns one dense row `[coefficients..., b]` per equality.

```mbti
pub fn[V : @luna-generic.Zero] Constraint::to_matrix(Self[V], Array[Variable]) -> Array[Array[V]]
```

Columns follow the order of the given variables. Inequalities are left out, so call it on the constraints of a program in standard form.

```moonbit
test "constraints" {
  let vars = nonneg(["x1", "x2"])
  let c : Constraint[Double] = Constraint::from_array(
    eq_array=[([1.0, 1.0], 4.0)],
    ineq_array=[([2.0, 1.0], "<=", 6.0)],
    vars,
  )
  inspect(
    c,
    content=(
      #|s.t. x1 + x2 = 4
      #|     2x1 + x2 <= 6
      #|    
    ),
  )
  debug_inspect(c.to_matrix(vars), content="[[1, 1, 4]]")
}
```

## Programs

### `Lp`

`Lp[V]` is a linear program: its variables, objective, constraints and the program matrix built from them.

```mbti
type Lp[V]
pub impl[V : Show + Eq + @luna-generic.Semiring] Show for Lp[V]
pub fn[V : Show + Eq + @luna-generic.Semiring] Lp::to_string(Self[V]) -> String
```

The functions that build a program return a new `Lp` and leave their argument unchanged. `Show` prints the objective, the constraints and every variable with its bounds.

### `Lp::new`, `Lp::cons_from_Array`, `Lp::reset_obj_byarray`

`Lp::new` creates a program without constraints; the other two replace its constraints or its objective coefficients.

```mbti
pub fn[V : @luna-generic.Zero] Lp::new(Obj_func[V], Array[Variable]) -> Self[V]
pub fn[V : Eq + @luna-generic.Semiring] Lp::cons_from_Array(Self[V], eq_array? : Array[(Array[V], V)], ineq_array? : Array[(Array[V], String, V)]) -> Self[V]
pub fn[V : Compare + @luna-generic.Semiring + @luna-generic.Zero] Lp::reset_obj_byarray(Self[V], Array[V]) -> Self[V]
```

`cons_from_Array` replaces all constraints, as `Constraint::from_array` with the program's variables. `reset_obj_byarray(coeffs)` keeps the sense and sets new objective coefficients.

### `Lp::from_matrix`

`Lp::from_matrix` creates a program with equality constraints from a program matrix.

```mbti
pub fn[V : Eq + @luna-generic.Semiring] Lp::from_matrix(@mutable.Matrix[V], Array[Variable], String) -> Self[V]
```

`Lp::from_matrix(m, vars, sense)` reads the objective from row 0 without its last entry, and the equality $a_i \cdot x = b_i$ from every further row $[a_i \mid b_i]$. The program keeps `m` itself as its matrix, without copying it.

### `Lp::to_standard`

`to_standard` returns the equivalent program in standard form.

```mbti
pub fn[V : Eq + @luna-generic.Semiring + Compare + Neg + @luna-generic.Zero] Lp::to_standard(Self[V]) -> Self[V]
```

The result minimises, has only equality constraints, and has non-negative right-hand sides:

- a maximisation objective is negated (`Obj_func::to_min`);
- an equality with $b < 0$ is multiplied by $-1$;
- every inequality receives a new variable `y1`, `y2`, ... (counting the inequalities in order), added with coefficient $+1$ to a `<=` row and $-1$ to a `>=` row, after multiplying the row by $-1$ when needed so that $b \ge 0$.

The new variables are appended to the variables of the program. The [design notes](../design/core.md) derive each case.

### `Lp::get_coeff_matrix`, `Lp::get_objfunc_vector`, `Lp::get_b_vector`

These read $A$, $c$ and $b$ from the program matrix.

```mbti
pub fn[V] Lp::get_coeff_matrix(Self[V]) -> @mutable.Matrix[V]
pub fn[V] Lp::get_objfunc_vector(Self[V]) -> Array[V]
pub fn[V] Lp::get_b_vector(Self[V]) -> Array[V]
```

The program matrix contains the objective and the equality constraints only, so these accessors describe a program with inequalities only after `to_standard`.

```moonbit
test "standard form" {
  let vars = nonneg(["x1", "x2"])
  let lp : Lp[Double] = Lp::new(Obj_func::from_array("max", [3.0, 4.0], vars), vars)
    .cons_from_Array(ineq_array=[([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], ">=", 2.0)])
  let s = lp.to_standard()
  inspect(
    s,
    content=(
      #|min  -3x1 + -4x2
      #|s.t. 2x1 + x2 + y1 = 12
      #|     x1 + 3x2 + -1y2 = 2
      #|      x1 : [0, 1.7976931348623157e+308] x2 : [0, 1.7976931348623157e+308] y1 : [0, 1.7976931348623157e+308] y2 : [0, 1.7976931348623157e+308]
      #|
    ),
  )
  debug_inspect(s.get_objfunc_vector(), content="[-3, -4, 0, 0]")
  debug_inspect(s.get_b_vector(), content="[12, 2]")
  inspect(
    s.get_coeff_matrix(),
    content=(
      #||2, 1, 1, 0|
      #||1, 3, 0, -1|
    ),
  )
}
```

## Solving

### `Lp::two_stage`

`two_stage` solves a program in standard form with the two-phase simplex method.

```mbti
pub fn[V : @luna-generic.Zero + @luna-generic.One + Compare + Mul + Div + Sub + ApproximatelyZero + Show + Neg] Lp::two_stage(Self[V]) -> (Array[V], V)
```

Call it on the result of `to_standard`. It returns the values of all variables of the standard form, including the added `y` variables, in the order of the program's variables, and the optimal value of the standard form. The standard form always minimises, so for a program that maximises, the maximum is the *negation* of the returned value.

`two_stage` aborts when the program is infeasible (phase 1 ends with a non-zero artificial objective) and when it is unbounded. Each simplex run stops after 1000 iterations and prints `Maximum iterations reached, may not have converged` if it has not finished; the result is then returned without an error.

> [!WARNING]
> The objective row is built by `Obj_func::to_vector`, which lists the non-zero objective coefficients in the order of the variable names. The solver therefore optimises the wrong objective when an objective coefficient is zero or when the variables are not declared in name order (for example `b` before `a`, or `x2` before `x10`). Until this is fixed, give every variable a non-zero objective coefficient and declare variables in name order.

```moonbit
test "solve" {
  let vars = nonneg(["x1", "x2"])
  let lp : Lp[Double] = Lp::new(Obj_func::from_array("max", [3.0, 4.0], vars), vars)
    .cons_from_Array(ineq_array=[([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)])
  let (x, value) = lp.to_standard().two_stage()
  debug_inspect(x, content="[5.199999999999999, 1.6000000000000005, 0, 0]")
  inspect(-value, content="22")
}
```

### `Lp::pivot`

`pivot` performs one Gauss–Jordan pivot of a tableau in place.

```mbti
pub fn[V : @luna-generic.Zero + Compare + Div + Mul + Sub] Lp::pivot(@mutable.Matrix[V], Int, Int) -> Unit
```

`Lp::pivot(t, r, s)` divides row `r` by the pivot $t_{rs}$ and subtracts $t_{is}$ times the new row `r` from every other row `i`, including row 0, so that column `s` becomes the unit vector $e_r$. It aborts when the position lies outside the matrix or the pivot is exactly zero.

### `Lp::simplex_iteration`

`simplex_iteration` runs the simplex method on a tableau in place.

```mbti
pub fn[V : @luna-generic.Zero + Compare + Sub + Mul + Div + Show] Lp::simplex_iteration(@mutable.Matrix[V], max_iterations? : Int, debug? : Bool) -> Unit
```

The tableau must be in canonical form: row 0 holds the reduced costs and $-z$ in its last column, every basic column is a unit vector, and the right-hand sides are non-negative. Each iteration enters the column with the most negative entry of row 0 (the leftmost one on ties), and leaves the row with the smallest ratio $\bar b_i / \bar a_{is}$ over the rows with $\bar a_{is} > 0$ (the topmost one on ties). The run stops when row 0 has no negative entry, aborts with `Problem is unbounded` when the entering column has no positive entry, and stops after `max_iterations` iterations (1000 by default) with a message. With `debug=true` it prints every pivot and the tableau after it.

```moonbit
test "simplex by hand" {
  // max 3x1 + 4x2, 2x1 + x2 + y1 = 12, x1 + 3x2 + y2 = 10; y1, y2 basic
  let t : @la.Matrix[Double] = @la.Matrix::from_2d_array([
    [-3.0, -4.0, 0.0, 0.0, 0.0],
    [2.0, 1.0, 1.0, 0.0, 12.0],
    [1.0, 3.0, 0.0, 1.0, 10.0],
  ])
  Lp::pivot(t, 2, 1) // x2 enters, y2 leaves
  inspect(t[0][4], content="13.333333333333334")
  Lp::simplex_iteration(t)
  inspect(t[0][4], content="22")
}
```

### `Lp::phase_1`, `Lp::phase_2`

`phase_1` and `phase_2` are the two halves of `two_stage`.

```mbti
pub fn[V : @luna-generic.Zero + @luna-generic.One + Compare + Sub + Compare + Div + Mul + Show] Lp::phase_1(@mutable.Matrix[V], Array[Int]) -> @mutable.Matrix[V]
pub fn[V : @luna-generic.Zero + @luna-generic.One + ApproximatelyZero + Div + Sub + Mul + Show + Compare] Lp::phase_2(Array[Variable], Array[V], @mutable.Matrix[V]) -> (Array[V], V)
```

`Lp::phase_1(t, artificial_index)` takes a tableau extended with artificial columns whose row 0 holds $1$ in each artificial column and $0$ elsewhere. `artificial_index[i]` is the column of the artificial variable of constraint `i`, or `0` when the constraint has none. It subtracts each constraint row with an artificial variable from row 0, which puts the tableau in canonical form, runs `simplex_iteration` and returns the same matrix.

`Lp::phase_2(vars, c, t)` checks that phase 1 reached zero, copies the columns of the first `vars.length()` variables and the right-hand side into a new tableau, writes the objective `c` into row 0, eliminates the basic columns (recognised as columns equal to a unit vector, within `ApproximatelyZero`) from row 0, runs `simplex_iteration` and returns the basic solution together with the last entry of row 0, which is $-z$. It aborts with `W* from Phase1 isn't zero, Lp doesn't have solution` when phase 1 ended with a non-zero objective.

The helper that builds the phase 1 tableau and `artificial_index` from a program is private; use `two_stage` unless you build tableaux yourself.

## Numeric tolerance

### `ApproximatelyZero`

`ApproximatelyZero` decides whether a value counts as zero in phase 2.

```mbti
pub trait ApproximatelyZero {
  fn is_zero_eps(Self) -> Bool
}
pub impl ApproximatelyZero for Int
pub impl ApproximatelyZero for Double
```

An `Int` is zero only when it equals `0`. A `Double` is zero when $|x| < 10^{-15}$, an absolute threshold. Implement the trait for your own coefficient type to use it with `two_stage`.

### `double_equal_to_zero`

`double_equal_to_zero` calls `is_zero_eps`.

```mbti
pub fn[V : ApproximatelyZero] double_equal_to_zero(V) -> Bool
```

```moonbit
test "tolerance" {
  assert_true(@lp.double_equal_to_zero(1.5e-17))
  assert_false(@lp.double_equal_to_zero(1.0e-12))
  assert_true(@lp.double_equal_to_zero(0))
}
```

## Deprecated

The promoted methods below are kept for source compatibility. They are hidden from the interface file and warn when called from another package.

| Method | Replacement |
| --- | --- |
| `Variable::not_equal`, `Poly::not_equal` | `a != b` |
| `Variable::op_lt`, `op_le`, `op_gt`, `op_ge` | `<`, `<=`, `>`, `>=` |
| `Variable::output`, `Poly::output`, `Obj_func::output`, `Constraint::output`, `Lp::output` | `to_string()` or `"\{x}"` |
