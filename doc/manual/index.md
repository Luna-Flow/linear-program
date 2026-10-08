# linear-program

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/linear-program/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

linear-program is a [MoonBit](https://www.moonbitlang.com/) library for writing linear programs and solving them with the two-phase simplex method. Coefficients are generic over the algebraic traits of [luna-generic](https://lunaflow.cn/en/luna-generic/), and the simplex tableau is a mutable matrix from [linear-algebra](https://lunaflow.cn/en/linear-algebra/). Every step of the solver is public, so the library also serves to follow the simplex method by hand.

## Packages

All public names live in the single package at `src`, documented as `core`.

| Package | Contents | API | Tutorial | Design |
| --- | --- | --- | --- | --- |
| `core` (`src`, import path `linear-program`) | Variables, linear expressions, objectives and constraints (`Variable`, `Poly`, `Obj_func`, `Constraint`); programs and standard form (`Lp`, `Lp::to_standard`); the two-phase simplex solver (`Lp::two_stage`, `Lp::pivot`, `Lp::simplex_iteration`, `Lp::phase_1`, `Lp::phase_2`); the tolerance trait `ApproximatelyZero`. | [API](api/core.md) | [Tutorial](tutorial/core.md) | [Design](design/core.md) |

## Reading paths

- **New to linear programming.** Work through the [tutorial](tutorial/core.md): it solves a production problem, then a minimisation with `>=` constraints, then pivots a tableau by hand. Keep the [design notes](design/core.md) open for the meaning of standard form, reduced costs and the two phases.
- **Using the solver.** The [tutorial](tutorial/core.md) quick start and its list of common pitfalls are enough to solve small programs. The [API reference](api/core.md) states the exact behaviour of every function, including what aborts.
- **Contributing.** Read the [design notes](design/core.md), especially the invariants and the known defects, then the [contribution guidelines](contributing.md).

## Toolchain and installation

The library requires MoonBit with `moonc` 0.10 or newer and depends on `Luna-Flow/luna-generic` 0.3.3 and `Luna-Flow/linear-algebra` 0.4.7.

> [!NOTE]
> The module is named `linear-program`, without the `Luna-Flow/` namespace, so it cannot be added from mooncakes under the Luna-Flow organisation. Add a checkout of the repository to the `members` of your `moon.work` and list `"linear-program@0.1.0"` in the `import` block of your `moon.mod`. The [tutorial](tutorial/core.md) shows the complete setup.

Import the package in your `moon.pkg`:

```text
import {
  "linear-program" @lp,
  "Luna-Flow/linear-algebra/mutable" @la,
}
```

Before opening a pull request, run `moon fmt`, `moon check --target all`, `moon info` and `moon test`, or the `ready_to_pr.sh` script.
