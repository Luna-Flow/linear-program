# linear-program

[![img](https://img.shields.io/badge/Maintainer-KCN--judu-violet)](https://github.com/KCN-judu) [![img](https://img.shields.io/badge/Collaborator-CAIMEOX-purple)](https://github.com/CAIMEOX) [![img](https://img.shields.io/badge/License-Apache%202.0-blue)](https://github.com/Luna-Flow/linear-program/blob/main/LICENSE) ![img](https://img.shields.io/badge/State-active-success)

## Introduction

linear-program is a [**MoonBit**](https://www.moonbitlang.cn/) library for defining linear programs and solving them with the two-phase simplex method. Coefficients are generic over the algebraic traits of [luna-generic](https://luna-flow.github.io/en/luna-generic/), and the simplex tableau is a mutable matrix from [linear-algebra](https://luna-flow.github.io/en/linear-algebra/).

## Features

- Decision variables, linear expressions, objective functions and constraints (`Variable`, `Poly`, `Obj_func`, `Constraint`).
- Programs built from coefficient arrays (`Lp::new`, `Lp::cons_from_Array`) or from a coefficient matrix (`Lp::from_matrix`).
- Conversion to standard form with slack and surplus variables (`Lp::to_standard`).
- A two-phase simplex solver (`Lp::two_stage`) whose steps are also public: `Lp::pivot`, `Lp::simplex_iteration`, `Lp::phase_1` and `Lp::phase_2`.

All public names live in the single package at `src`. The [API reference](api/core.md) lists them, the [design notes](design/core.md) explain the model and the solver, and the [tutorial](tutorial/core.md) solves two small programs from start to finish.

## How to contribute

We welcome contributions from the community, external developers, and individual enthusiasts! Whether you want to fix a bug, add a new feature, or improve the documentation, your participation is highly encouraged. To help you contribute smoothly, here are some simple steps:

1. Please choose a task from the current `issue` list that interests you. We recommend selecting something you are interested in or familiar with, as it will make it easier to get started and enjoy the process.
2. Fork our project and create a new branch in your personal repository. This way, you can start working on your changes without affecting the main project.
3. During development, please adhere to the coding style and guidelines in the [contribution guidelines](contributing.md). If your changes involve new features or bug fixes, please make sure to perform thorough testing to ensure everything works as expected.
4. Once you're done, submit your PR and provide a clear description of your changes to help us understand the modifications you've made. This will help us review and merge your code more quickly.
5. We will review your PR and may suggest improvements to ensure code quality. After approval, your contributions will be merged into the main branch.

Thank you again for your participation and contributions! Every effort helps make this project better. We look forward to seeing your great code!
