///|
struct Lp[V] {
  vars : Array[Variable]
  obj_func : Obj_func[V]
  constraint : Constraint[V]
  matrix : Matrix[V]
}

///|
pub impl[V : Show + Eq + Semiring] Show for Lp[V] with to_string(self) -> String {
  let mut s = self.obj_func.to_string() + "\n" + self.constraint.to_string()
  for x in self.vars {
    s = s + " " + x.show_all()
  }
  s + "\n"
}

///|
pub impl[V : Show + Eq + Semiring] Show for Lp[V] with output(self, l) -> Unit {
  l.write_string(self.to_string())
}

///|
/// the variable name can't be [y1,y2,...] or [z1,z2,...]
pub fn[V : Zero] Lp::new(
  new_objfunc : Obj_func[V],
  variable : Array[Variable]
) -> Lp[V] {
  {
    vars: variable,
    obj_func: new_objfunc,
    constraint: Constraint::new(),
    matrix: Lp::get_Matrix(variable, new_objfunc, Constraint::new()),
  }
}

///|
/// obj_func function: reset it by Array[V]
pub fn[V : Compare + Semiring + Zero] Lp::reset_obj_byarray(
  self : Lp[V],
  arr : Array[V]
) -> Lp[V] {
  let new_objfunc = self.obj_func.set_poly(Poly::from_var_array(arr, self.vars))
  {
    vars: self.vars,
    obj_func: new_objfunc,
    constraint: self.constraint,
    matrix: Lp::get_Matrix(self.vars, new_objfunc, self.constraint),
  }
}

///|
/// set constraint by Array
/// the lable in ineq_array must be ">=" or "<="
pub fn[V : Eq + Semiring] Lp::cons_from_Array(
  self : Lp[V],
  eq_array~ : Array[(Array[V], V)] = [],
  ineq_array~ : Array[(Array[V], String, V)] = []
) -> Lp[V] {
  let new_constraint = Constraint::from_array(eq_array~, ineq_array~, self.vars)
  {
    vars: self.vars,
    obj_func: self.obj_func,
    constraint: new_constraint,
    matrix: Lp::get_Matrix(self.vars, self.obj_func, new_constraint),
  }
}

///|
/// transform Matrix to Linear-program standard model
pub fn[V : Eq + Semiring] Lp::from_matrix(
  lp_matrix : Matrix[V],
  vars_for_matrix : Array[Variable],
  obj_type : String
) -> Lp[V] {
  let eq_array : Array[(Array[V], V)] = []
  let row_num = lp_matrix.row()
  let col_num = lp_matrix.col()
  for i in 1..<row_num {
    eq_array.append([
      (
        lp_matrix.row_to_array(i)[:col_num - 1].to_array(),
        lp_matrix[i][col_num - 1],
      ),
    ])
  }
  {
    vars: vars_for_matrix,
    obj_func: Obj_func::from_array(
      obj_type,
      lp_matrix.row_to_array(0)[:col_num].to_array(),
      vars_for_matrix,
    ),
    constraint: Constraint::from_array(eq_array~, vars_for_matrix),
    matrix: lp_matrix,
  }
}

///|
test "Lp_from_Matrix" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
    Variable::new("x4", 0.0, @double.max_value),
  ]
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [1, 2, 3, 4, 0],
    [4, 5, 0, 5, 1],
    [1, -4, 5, 1, 0],
    [0, 3, 8, 1, 2],
  ])
  let lp = Lp::from_matrix(matrix, vars, "min")
  println(lp)
}

///|
pub fn[V] Lp::get_coeff_matrix(self : Lp[V]) -> Matrix[V] {
  Matrix::make(self.matrix.row() - 1, self.matrix.col() - 1, fn(
    col_index : Int,
    row_index : Int
  ) -> V {
    self.matrix[col_index + 1][row_index]
  })
}

///| get obj_func coeff from matrix
pub fn[V] Lp::get_objfunc_vector(self : Lp[V]) -> Array[V] {
  self.matrix.row_to_array(0)[:self.matrix.col() - 1].to_array()
}

///|
pub fn[V] Lp::get_b_vector(self : Lp[V]) -> Array[V] {
  self.matrix.col_to_array(self.matrix.col() - 1)[1:].to_array()
}

///|
test "get A,c,b" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
    Variable::new("x4", 0.0, @double.max_value),
    Variable::new("x5", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("min", [1, 2, 3, 4, 5], vars)
  let eq_con = [([1, 2, 3, 0, 5], 0), ([1, 7, 0, 4, 3], 0)]
  let lp = Lp::new(obj_func, vars).cons_from_Array(eq_array=eq_con)
  println(lp.matrix)
  println(lp.get_coeff_matrix())
  println(lp.get_objfunc_vector())
  println(lp.get_b_vector())
}

///|
/// transform Lp from (Ax "= <= >=" b) to (Ax = b)
/// this function add some Variable to Lp, they are artificial variable、remainder,relaxation variable
/// also make sure all RHS is > 0
pub fn[V : Eq + Semiring + Compare + Neg + Zero] Lp::to_standard(
  self : Lp[V]
) -> Lp[V] {
  let new_objfunc = self.obj_func.to_min()
  let new_vars = self.vars.copy()
  let new_cons : Constraint[V] = { eq_poly: [], ineq_poly: [] }
  let mut count = 1
  self.constraint.eq_poly.each(fn(x) -> Unit {
    let (poly, b) = x
    if b < V::zero() {
      new_cons.add_eqpoly(-poly, -b)
    } else {
      new_cons.add_eqpoly(poly, b)
    }
  })
  //add remainder,relaxation variable for ineq_constraint
  count = 1
  self.constraint.ineq_poly.each(fn(x) -> Unit {
    let (poly, s, b) = x
    let variable = Variable::new("y" + count.to_string(), 0, @double.max_value)
    count += 1
    new_vars.append([variable])
    if s == ">=" {
      if b <= V::zero() {
        let temp_poly = -poly
        temp_poly.add_term_inplace(variable, V::one())
        new_cons.add_eqpoly(temp_poly, -b)
      } else {
        let temp_poly = poly.copy()
        temp_poly.add_term_inplace(variable, -V::one())
        new_cons.add_eqpoly(temp_poly, b)
      }
    } else if b >= V::zero() {
      let temp_poly = poly.copy()
      temp_poly.add_term_inplace(variable, V::one())
      new_cons.add_eqpoly(temp_poly, b)
    } else {
      let temp_poly = -poly
      temp_poly.add_term_inplace(variable, -V::one())
      new_cons.add_eqpoly(temp_poly, -b)
    }
  })
  {
    vars: new_vars,
    obj_func: new_objfunc,
    constraint: new_cons,
    matrix: Lp::get_Matrix(new_vars, new_objfunc, new_cons),
  }
}

///|
/// before use this function, Please make sure this LP have been standard
fn[V : Zero] Lp::get_Matrix(
  vars : Array[Variable],
  obj_func : Obj_func[V],
  constraint : Constraint[V]
) -> Matrix[V] {
  let res : Array[Array[V]] = []
  let var_num = vars.length()
  res.append([obj_func.to_vector(var_num)])
  res.append(constraint.to_matrix(vars))
  Matrix::from_2d_array(res)
}

///|
test "show" {
  //Define Vars
  //Variable::new(name, lowbound, upbound)
  let arr = [
    Variable::new("x1", 0.0, 100.0),
    Variable::new("x2", 0.0, 100.0),
    Variable::new("x3", 0.0, 100.0),
  ]
  //Define Object function
  let obj_func = Obj_func::from_array("max", [1.0, 2.0, 3.0], arr)
  //Define equal constraint
  // (poly, b-value)
  let eqarr = [([2.0, 2.0, 3.0], 100.0)]
  //Define inequal constraint
  // (poly, labal, b-value)
  let ineqarr = [([2.5, 0.0, 4.7], ">=", 0.0), ([-1.7, 2.5, 12], "<=", 0.0)]
  //Define Liner Program
  let lp2 = Lp::new(obj_func, arr).cons_from_Array(
    eq_array=eqarr,
    ineq_array=ineqarr,
  )
  let lp3 = lp2.to_standard()
  println(lp2)
  println(lp2.matrix)
  println(lp3)
  println(lp3.matrix)
}

// *** Solve Linear Program *** //

///|
/// add artificial variables and get init_solve
/// return fmt (artificial_matrix, init_solve, artificial_index)
fn[V : Zero + Compare + One] Lp::add_artificial(
  self : Lp[V]
) -> (Matrix[V], Array[V], Array[Int]) {
  let coeff = self.get_coeff_matrix()
  let b_array = self.get_b_vector()
  let init_solve : Array[V] = Array::make(self.vars.length(), V::zero())
  let artificial_index = Array::make(coeff.row(), 0)
  let mut articifical_num = 0

  // Count the number of non-zero elements in each column
  let nozeronum_bycol = Array::make(coeff.col(), 0)
  for i in 0..<coeff.row() {
    for j in 0..<coeff.col() {
      if coeff[i][j] != V::zero() {
        nozeronum_bycol[j] += 1
      }
    }
  }
  // establish artificial_matrix
  // let artificial_matrix : Array[Array[V]] = Array::make(coeff.row(), Array::make(coeff.col(), V::zero())) 
  let artificial_matrix = Matrix::new(coeff.row(), coeff.row(), V::zero())
  for i in 0..<coeff.row() {
    for j in 0..<coeff.col() {
      // find unit_col in this row, need't add artificial variables in this row
      if coeff[i][j] == V::one() && nozeronum_bycol[j] == 1 {
        init_solve[j] = b_array[i] // make X(j) = b_array[i]
        break
      }
    } else {
      // need add artificial variables in this row
      for k in 0..<coeff.row() {
        if k == i {
          artificial_matrix[k][articifical_num] = V::one()
        }
      }
      init_solve.append([b_array[i]])
      artificial_index[i] = coeff.col() + articifical_num
      articifical_num += 1
    }
  }
  let new_col = coeff.col() + articifical_num
  let mut obj_func = Array::make(new_col, V::zero())
  if articifical_num > 0 {
    // make new_obj_func for artificial_variables
    for i in 0..<new_col {
      if i < coeff.col() {
        obj_func[i] = V::zero()
      } else {
        obj_func[i] = V::one()
      }
    }
  } else {
    // no artificial_variables
    obj_func = self.get_objfunc_vector()
  }
  (
    // integrate self.matrix and artificial_matrix, get the full_matrix
    Matrix::make(coeff.row() + 1, coeff.col() + articifical_num + 1, fn(
      row,
      col
    ) -> V {
      if col >= coeff.col() + articifical_num {
        if row == 0 {
          V::zero()
        } else {
          b_array[row - 1]
        }
      } else if row == 0 {
        obj_func[col]
      } else if col < coeff.col() {
        coeff[row - 1][col]
      } else {
        artificial_matrix[row - 1][col - coeff.col()]
      }
    }),
    init_solve,
    artificial_index,
  )
}

///|
test "artificial_matrix" {
  // test 1
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
    Variable::new("x3", 0.0, @double.max_value),
    Variable::new("x4", 0.0, @double.max_value),
  ]
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [1, 2, 3, 4, 0],
    [4, 1, 0, 6, 1],
    [1, 3, 1, 0, 0],
    [-1, 4, 7, 1, 2],
  ])
  let lp = Lp::from_matrix(matrix, vars, "min")
  println("LP问题的矩阵形式,第一行为目标函数： \n\{lp.matrix}")
  let x = lp.add_artificial()
  println("添加人工变量后的LP矩阵：\n\{x.0}")
  println("初始解： \{x.1}")
  println("单位列的索引： \{x.2}")

  //test 2
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("max", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  println("LP问题的矩阵形式,第一行为目标函数： \n\{lp.matrix}")
  let x = lp.add_artificial()
  println("添加人工变量后的LP矩阵：\n\{x.0}")
  println("初始解： \{x.1}")
  println("单位列的索引： \{x.2}")
}

///|
pub fn[V : Zero + Compare + Div + Mul + Sub] Lp::pivot(
  matrix : Matrix[V],
  row : Int,
  col : Int
) -> Unit {
  let m_row = matrix.row()
  let m_col = matrix.col()
  guard row < m_row && col < m_col
  let pivot_val = matrix[row][col]
  if pivot_val == V::zero() {
    println("pivot error, (\{row}, \{col}) is zero!")
  } else {
    for j in 0..<m_col {
      matrix[row][j] = matrix[row][j] / pivot_val
    }
    for i in 0..<m_row {
      if i == row {
        continue
      }
      let factor = matrix[i][col]
      for j in 0..<m_col {
        matrix[i][j] = matrix[i][j] - factor * matrix[row][j]
      }
    }
  }
}

///|
test "pivot" {
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [1, 2, 3, 4, 0],
    [4, 1, 0, 6, 1],
    [1, 3, 1, 0, 0],
    [-1, 4, 7, 1, 2],
  ])
  println(Lp::pivot(matrix, 1, 1))
}

///|
pub fn[V : Zero + One + Compare + Sub + Compare + Div + Mul] Lp::phase_1(
  p1_matrix : Matrix[V],
  artificial_index : Array[Int]
) -> Matrix[V] {
  // let (matrix, _, artificial_index) = self.add_artificial()
  // let p1_matrix = matrix
  let row = p1_matrix.row()
  let col = p1_matrix.col()
  for index, col_num in artificial_index {
    if p1_matrix[0][col_num] == V::one() {
      for j in 0..<col {
        p1_matrix[0][j] = p1_matrix[0][j] - p1_matrix[index + 1][j]
      }
    }
  }

  //println(p1_matrix)
  //println(artificial_index)
  while true {

    // find in_base_var
    let mut in_base_index = 0
    let mut flag = true
    for i in 0..<(col - 1) {
      if p1_matrix[0][i] < V::zero() &&
        p1_matrix[0][i] <= p1_matrix[0][in_base_index] {
        in_base_index = i
        flag = false
      }
    } else {
      if flag {
        break
      }
    }

    // find out_base_var
    let mut per_ratio = V::zero()
    let mut out_base_index = -1
    flag = true
    for j in 1..<row {
      if p1_matrix[j][in_base_index] == V::zero() ||
        p1_matrix[j][col - 1] / p1_matrix[j][in_base_index] <= V::zero() {
        continue
      } else {
        let ratio = p1_matrix[j][col - 1] / p1_matrix[j][in_base_index]
        if flag == true || per_ratio > ratio {
          per_ratio = ratio
          out_base_index = j
          flag = false
        }
      }
    } else {
      if flag {
        println("Phase1 no_bound result")
        break
      }
    }

    //println("main value:(\{out_base_index}, \{in_base_index})") 
    //println("By col index, in_base_index: \{in_base_index}, out_base_index: \{artificial_index[out_base_index-1]}")

    Lp::pivot(p1_matrix, out_base_index, in_base_index)
    //println(p1_matrix)
  }
  p1_matrix
}

///|
test "phase1" {
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("max", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  let artificial = lp.add_artificial()
  let x = Lp::phase_1(artificial.0, artificial.2)
  println(x)
  println("\n")
  let matrix : Matrix[Double] = Matrix::from_2d_array([
    [5, 4, 0],
    [2, 3, 7],
    [3, 2, 8],
  ])
  let lp = Lp::from_matrix(matrix, vars, "max")
  let artificial = lp.add_artificial()
  let x = Lp::phase_1(artificial.0, artificial.2)
  println(x)
  println("\n")
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
  let lp = Lp::from_matrix(matrix, vars, "min")
  let artificial = lp.add_artificial()
  let x = Lp::phase_1(artificial.0, artificial.2)
  println(x)
  println("\n")
}

///| get base_best_solve from phase1 matrix
pub fn[V : Zero + Compare + One + Neg] Lp::phase_2(
  var_array : Array[Variable],
  matrix : Matrix[V]
) -> Array[V] {
  let row = matrix.row()
  let col = matrix.col()
  let var_num = var_array.length()
  guard var_num == col - 1 ||
    (matrix[0][col - 1] < V::one() && matrix[0][col - 1] > -V::one()) else {
    abort("W* from Phase1 isn't zero, Lp doesn't have solution ")
  }
  let best_base_solve = Array::make(var_num, V::zero())

  // Count the number of non-zero elements in each column
  let nozeronum_bycol = Array::make(var_num, 0)
  for i in 0..<row {
    for j in 0..<var_num {
      if matrix[i][j] != V::zero() {
        nozeronum_bycol[j] += 1
      }
    }
  }
  for i in 1..<row {
    for j in 0..<var_num {
      if matrix[i][j] == V::one() && nozeronum_bycol[j] == 1 {
        best_base_solve[j] = matrix[i][col - 1]
      }
    }
  }
  best_base_solve
}

///|
test "phase2" {
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
  println(lp)
  let artificial = lp.add_artificial()
  let phase1 = Lp::phase_1(artificial.0, artificial.2)
  println(phase1)
  let phase2 = Lp::phase_2(vars, phase1)
  let obj_func = lp.get_objfunc_vector()
  let mut res = 0.0
  for index, x in obj_func {
    res = res + x * phase2[index]
  }
  println(
    "variables：\{vars}, The_best_base_solve：\{phase2}\nThe Object_function result：\{res}",
  )
}

///| make sure the to_standard() has been done
pub fn[V : Eq + Zero + One + Compare + Mul + Div + Sub + Add + Neg] Lp::two_stage(
  self : Lp[V]
) -> (Array[V], V) {
  let artificial = self.add_artificial()
  let phase1 = Lp::phase_1(artificial.0, artificial.2)
  let phase2 = Lp::phase_2(self.vars, phase1)
  let obj_func = self.get_objfunc_vector()
  let mut res = V::zero()
  for index, x in obj_func {
    res = res + x * phase2[index]
  }
  (phase2, res)
}

///|
test "two_stage" {
  // example 1  equal_constrains
  // min cx
  // s.t. Ax=b
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
  println(vars)
  println(res.0)
  println(res.1)

  // example 2  constrains'labels are '<=' 
  // max cx
  // s.t.  Ax <= b
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
  println(vars)
  println(res.0)
  println(-res.1) //because source problem is "MAX", so real_res = -res

  // example 3  constrains'labels are '>=' 
  // min cx
  // s.t.  Ax >= b
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("min", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], ">=", 12.0), ([1.0, 3.0], ">=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  let res = lp.two_stage()
  println(vars)
  println(res.0)
  println(res.1)
  println("\n")

  // special example 1
  // min cx
  // s.t. Ax <= b
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("min", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], "<=", 12.0), ([1.0, 3.0], "<=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  println(lp)
  let res = lp.two_stage()
  println(vars)
  println(res.0)
  println(res.1)
  println("\n")
  // special example 2
  // max cx
  // s.t. Ax >= b
  let vars = [
    Variable::new("x1", 0.0, @double.max_value),
    Variable::new("x2", 0.0, @double.max_value),
  ]
  let obj_func = Obj_func::from_array("max", [3.0, 4.0], vars)
  let ineq = [([2.0, 1.0], ">=", 12.0), ([1.0, 3.0], ">=", 10.0)]
  let lp = Lp::new(obj_func, vars)
    .cons_from_Array(ineq_array=ineq)
    .to_standard()
  println(lp)
  let res = lp.two_stage()
  println(vars)
  println(res.0)
  println(res.1)
  println("\n")

  // no-solve example 1
  // let vars = [
  //   Variable::new("x1", 0.0, @double.max_value),
  //   Variable::new("x2", 0.0, @double.max_value)
  // ]
  // let obj_func = Obj_func::from_array(
  //   "min",
  //   [3.0, 4.0],
  //   vars
  // ) 
  // let ineq = [
  //   ([2.0, 1.0], ">=", 12.0),
  //   ([2.0, 1.0], "<=", 10.0)
  // ]
  // let lp = Lp::new(obj_func, vars).cons_from_Array(ineq_array = ineq).to_standard()
  // println(lp)
  // let res = lp.two_stage()
  // println(vars)
  // println(res.0)
  // println(res.1)
  // println("\n")

}
