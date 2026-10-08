# Changelog

All notable changes to this project are documented in this file.

## Unreleased

### Changed

- Migrated to MoonBit 0.10 (`moonc` 0.10 or newer is required).
- Dependencies bumped from `Luna-Flow/luna-generic` 0.2.0-alpha-1 and `Luna-Flow/linear-algebra` 0.1.5-beta-1 to `Luna-Flow/luna-generic` 0.4.0 and `Luna-Flow/linear-algebra` 0.4.7. The package uses only `Zero`, `One` and `Semiring` from luna-generic, so nothing deprecated in luna-generic 0.4.0 is used and no code change is needed.
- The manifests moved from `moon.mod.json` and `moon.pkg.json` to the `moon.mod` and `moon.pkg` formats.
- The interface file is now `src/pkg.generated.mbti`; the stale `src/linear-program.mbti` was removed.
- `typealias` and `traitalias` declarations were replaced by `using` imports, and `Poly` is now a struct wrapping a `SortedMap`. The public API is unchanged apart from the points below.
- Trait methods are promoted explicitly in `src/extends.mbt`: `Variable::{equal, compare, to_string, one}`, `Poly::{equal, neg, to_string}` and `to_string` for `Obj_func`, `Constraint` and `Lp` stay methods. `not_equal`, `op_lt`/`op_le`/`op_gt`/`op_ge` and `output` are kept as deprecated, hidden methods; use the operators and `to_string` instead.
- `Lp::two_stage` and `Lp::phase_2` no longer require `Eq` on the coefficient type.
- Optional arguments are declared with `?` (`eq_array?`, `ineq_array?`, `max_iterations?`, `debug?`); call sites are unchanged.
- `Lp::pivot` aborts with a message naming the position when the pivot lies outside the tableau.
- Tests use `debug_inspect` for arrays.

### Documentation

- Documentation rewritten (API, tutorial and design pages for `core`, and the manual overview) with zh_CN and ja_JP translations. The design notes derive the standard form, reduced costs, the optimality and unboundedness tests and the two phases, and list known defects of the solver.
- Fixed the API page link to the interface file.
- The README describes the current version only.
- The manual follows the luna-generic layout (overview with Install, Pages, exported items and reading paths; API Purpose and Importing; tutorial task table; design Constraints).
- Logic review of the manual against the code. `ApproximatelyZero` is read-only outside the package, so the tutorial no longer shows a custom coefficient type. Newly documented defects, each reproduced: an artificial variable left basic after phase 1 makes phase 2 return a point that violates a constraint or abort as unbounded; a starting unit column with a non-zero cost leaves row 0 non-canonical and can abort as unbounded; Beale's example cycles until the iteration limit. The design notes derive why each defect breaks the ratio or the stopping test.

## 0.1.0

- Variables, linear expressions, objectives and constraints; programs built from arrays or from a matrix; conversion to standard form; the two-phase simplex solver with public `pivot`, `simplex_iteration`, `phase_1` and `phase_2`; the `ApproximatelyZero` tolerance trait.
