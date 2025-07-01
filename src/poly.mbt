///|
type Poly[V] @sorted_map.T[Variable, V] derive(Eq)

///|
pub impl[V : Eq + Show + Semiring + @lg.One] Show for Poly[V] with to_string(
  self
) -> String {
  let mut s = ""
  let mut fst = true
  self
  .inner()
  .each(fn(variable, coff) -> Unit {
    if not(fst) {
      s += " + "
    }
    if coff == V::one() {
      s += variable.to_string()
    } else if coff == V::zero() {
      s += ""
    } else {
      s += coff.to_string()
      s += variable.to_string()
    }
    fst = false
  })
  s
}

///|
pub impl[V : Eq + Show + Semiring + One] Show for Poly[V] with output(self, l) {
  l.write_string(self.to_string())
}

///|
pub impl[V : Eq + Semiring + Compare + Zero + Neg] Neg for Poly[V] with op_neg(
  self : Poly[V]
) -> Poly[V] {
  let m = Poly::new()
  self
  .inner()
  .each(fn(variable : Variable, coeff : V) -> Unit {
    m.add_term_inplace(variable, -coeff)
  })
  m
}

///|
test "Neg" {
  let x1 : Variable = { name: "x1", low_bound: -1.0, up_bound: 1.0 }
  let x2 : Variable = { name: "x2", low_bound: -1.0, up_bound: 1.0 }
  let x3 : Variable = { name: "x3", low_bound: -1.0, up_bound: 1.0 }
  let poly = Poly::new()
  poly.add_term_inplace(x1, 3.5)
  poly.add_term_inplace(x2, 1.5)
  poly.add_term_inplace(x3, -2)
  println(poly)
  println(-poly)
  println(-(-poly))
}

///|
pub fn[V] Poly::new() -> Poly[V] {
  @sorted_map.new()
}

///|
pub fn[V : Eq + Compare + Semiring] Poly::from_var_array(
  arr : Array[V],
  vars : Array[Variable]
) -> Poly[V] {
  let res = Poly::new()
  for index, x in arr {
    if index < arr.length() && x != V::zero() {
      res.inner().add(vars[index], x)
    }
    if index >= arr.length() {
      res.inner().add(Variable::one(), x)
    }
  }
  res
}

///|
pub fn[V] Poly::to_Array(self : Poly[V]) -> Array[V] {
  let res : Array[V] = []
  for x in self.inner() {
    res.append([x.1])
  }
  res
}

///|
pub fn[V : Zero] Poly::to_vector(
  self : Poly[V],
  vars : Array[Variable]
) -> Array[V] {
  let res : Array[V] = []
  for variable in vars {
    res.append(
      match self.inner().get(variable) {
        None => [V::zero()]
        Some(x) => [x]
      },
    )
  }
  res
}

///|
pub fn[V : Eq + Semiring + Compare + Zero] Poly::add_term_inplace(
  self : Poly[V],
  variable : Variable,
  coeff : V
) -> Unit {
  guard coeff != V::zero() else { return }
  if self.inner().get(variable) is None {
    self.inner().add(variable, coeff)
  } else {
    let new_coeff = self.inner().get(variable).unwrap() + coeff
    guard new_coeff != V::zero() else { self.inner().remove(variable) }
    self.inner()[variable] = new_coeff
  }
}

///|
pub fn[V : Eq + Semiring + Compare + Zero] Poly::copy(
  self : Poly[V]
) -> Poly[V] {
  let m = Poly::new()
  self
  .inner()
  .each(fn(variable : Variable, coeff : V) -> Unit {
    m.add_term_inplace(variable, coeff)
  })
  m
}
