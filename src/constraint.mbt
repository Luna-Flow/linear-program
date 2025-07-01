///|
struct Constraint[V] {
  eq_poly : Array[(Poly[V], V)]
  ineq_poly : Array[(Poly[V], String, V)]
}

///|
pub impl[V : Show + Eq + Semiring] Show for Constraint[V] with to_string(
  self : Constraint[V]
) -> String {
  let mut res = ""
  for x in self.eq_poly {
    res += x.0.to_string() + " = " + x.1.to_string() + "\n     "
  }
  for x in self.ineq_poly {
    res += x.0.to_string() + " \{x.1} " + x.2.to_string() + "\n    "
  }
  "s.t. " + res
}

///|
pub impl[V : Show + Eq + Semiring] Show for Constraint[V] with output(self, l) {
  l.write_string(self.to_string())
}

///|
/// poly_number : the constraint number this PL question used
pub fn[V] Constraint::new() -> Constraint[V] {
  let ep : Array[(Poly[V], V)] = []
  let iep : Array[(Poly[V], String, V)] = []
  { eq_poly: ep, ineq_poly: iep }
}

///|
pub fn[V] Constraint::add_eqpoly(
  self : Constraint[V],
  poly : Poly[V],
  b : V
) -> Unit {
  self.eq_poly.append([(poly, b)])
}

///|
/// s : '>=' or '<='
pub fn[V] Constraint::add_ineqpoly(
  self : Constraint[V],
  poly : Poly[V],
  s : String,
  b : V
) -> Unit {
  self.ineq_poly.append([(poly, s, b)])
}

///|
pub fn[V] Constraint::change_eqpoly(
  self : Constraint[V],
  index : Int,
  poly : Poly[V],
  b : V
) -> Unit {
  guard index > 0 && index < self.eq_poly.capacity() else {
    abort("Error, index is out of bound")
  }
  self.eq_poly[index - 1] = (poly, b)
}

///|
pub fn[V] Constraint::change_ineqpoly(
  self : Constraint[V],
  index : Int,
  poly : Poly[V],
  s : String,
  b : V
) -> Unit {
  guard index > 0 && index < self.eq_poly.capacity() else {
    abort("Error, index is out of bound")
  }
  self.ineq_poly[index - 1] = (poly, s, b)
}

///|
test "add_eqpoly" {
  let x1 : Variable = { name: "x1", low_bound: -1.0, up_bound: 1.0 }
  let x2 : Variable = { name: "x2", low_bound: -1.0, up_bound: 1.0 }
  let x3 : Variable = { name: "x3", low_bound: -1.0, up_bound: 1.0 }
  let con = Constraint::new()
  let poly = Poly::new()
  poly.add_term_inplace(x1, 3.5)
  poly.add_term_inplace(x2, 1.5)
  poly.add_term_inplace(x3, -2)
  con.add_eqpoly(poly, 3.7)
  println(con)
  let poly = Poly::new()
  poly.add_term_inplace(x1, 3.5)
  poly.add_term_inplace(x2, 1.5)
  poly.add_term_inplace(x3, -2)
  con.add_eqpoly(poly, 3.9)
  println(con)
}

///|
pub fn[V : Eq + Compare + Semiring] Constraint::from_array(
  eq_array~ : Array[(Array[V], V)] = [],
  ineq_array~ : Array[(Array[V], String, V)] = [],
  vars : Array[Variable]
) -> Constraint[V] {
  let c = Constraint::new()
  for eq in eq_array {
    c.add_eqpoly(Poly::from_var_array(eq.0, vars), eq.1)
  }
  for ineq in ineq_array {
    guard ineq.1 == ">=" || ineq.1 == "<=" else {
      abort("there is not '>=' or '<=' in ineq Array")
    }
    c.add_ineqpoly(Poly::from_var_array(ineq.0, vars), ineq.1, ineq.2)
  }
  c
}

///|
/// before use this function.Please make sure This Lp have been transformed to starand
pub fn[V : Zero] Constraint::to_matrix(
  self : Constraint[V],
  vars : Array[Variable]
) -> Array[Array[V]] {
  let res : Array[Array[V]] = []
  for x in self.eq_poly {
    let temp_array = x.0.to_vector(vars)
    temp_array.append([x.1])
    res.append([temp_array])
  }
  res
}
