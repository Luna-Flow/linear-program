# linear-program

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/linear-program/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

linear-program is a [MoonBit](https://www.moonbitlang.com/) library for writing linear programs with named variables and solving them with the two-phase simplex method. Every step of the solver (standard form, pivot, simplex iteration, phase 1, phase 2) is public, so the library is also a tool for learning and teaching the simplex method. This README describes version 0.1.0.

## Installation

The module is named `linear-program`, without the `Luna-Flow/` namespace, so it is not available as `Luna-Flow/linear-program` on mooncakes yet. Use a local checkout: add it to the `members` of your `moon.work`, together with checkouts of `luna-generic` and `linear-algebra`, and import it in your `moon.mod` and `moon.pkg`:

```text
// moon.mod
import {
  "linear-program@0.1.0",
  "Luna-Flow/linear-algebra@0.4.7",
}

// moon.pkg
import {
  "linear-program" @lp,
}
```

## Example

Maximise $3x_1 + 4x_2$ subject to $2x_1 + x_2 \le 12$, $x_1 + 3x_2 \le 10$, $x \ge 0$:

```moonbit
using @lp {type Variable, type Obj_func, type Lp}

test {
  let x = [Variable::new("x1", 0.0, 100.0), Variable::new("x2", 0.0, 100.0)]
  let lp : Lp[Double] = Lp::new(Obj_func::from_array("max", [3.0, 4.0], x), x)
    .cons_from_Array(ineq_array=[([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)])
  let (solution, value) = lp.to_standard().two_stage()
  debug_inspect(solution, content="[5.199999999999999, 1.6000000000000005, 0, 0]")
  inspect(-value, content="22") // the standard form minimises -3x1 - 4x2
}
```

## Packages

| Package | Contents |
| --- | --- |
| `linear-program` (`src`, documented as `core`) | `Variable`, `Poly`, `Obj_func`, `Constraint`, `Lp`, the two-phase simplex solver and the `ApproximatelyZero` tolerance trait |

## Requirements

MoonBit toolchain with `moonc` 0.10 or newer. Dependencies: `Luna-Flow/luna-generic` 0.3.3 and `Luna-Flow/linear-algebra` 0.4.7.

## Documentation

- Online manual (English, Chinese, Japanese): <https://lunaflow.cn/en/linear-program/>
- English source: [`doc/manual/index.md`](doc/manual/index.md), with the [tutorial](doc/manual/tutorial/core.md), the [API reference](doc/manual/api/core.md) and the [design notes](doc/manual/design/core.md).
- The solver has known defects that can return a wrong optimum, a point that violates a constraint or a false "unbounded"; the API reference lists them with examples. Check every solution against the constraints.
- Changes between versions: [`CHANGELOG.md`](CHANGELOG.md).

## Contributing

Contributions are welcome. Read the [contribution guidelines](doc/manual/contributing.md) and the [design notes](doc/manual/design/core.md), which list the known defects of the solver, and run `ready_to_pr.sh` before opening a pull request.

## License

Apache-2.0. See [`LICENSE`](LICENSE).
