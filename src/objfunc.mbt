///|
priv enum Obj_type {
  Minimize
  Maximize
}

///|
struct Obj_func[V] {
  sense : Obj_type
  obj_poly : Poly[V]
}

///|
pub impl[V : Eq + Show + Semiring] Show for Obj_func[V] with output(self, l) {
  l
  ..write_string(
    match self.sense {
      Minimize => "min  "
      Maximize => "max  "
    },
  )
  ..write_object(self.obj_poly)
}

///|
pub fn[V] Obj_func::new(s : String) -> Obj_func[V] {
  {
    sense: match s {
      "Min" | "Minimize" | "min" | "minimize" | "MIN" => Minimize
      "Max" | "MAX" | "max" | "Maximize" | "maximize" => Maximize
      _ => abort("Error Obj_type , Please choose 'min' or 'max'!")
    },
    obj_poly: Poly::new(),
  }
}

///|
pub fn[V] Obj_func::set_poly(self : Obj_func[V], poly : Poly[V]) -> Obj_func[V] {
  { sense: self.sense, obj_poly: poly }
}

///|
pub fn[V : Eq + Semiring + Zero] Obj_func::add_term_inplace(
  self : Obj_func[V],
  variable : Variable,
  coeff : V,
) -> Unit {
  self.obj_poly.add_term_inplace(variable, coeff)
}

///|
pub fn[V : Eq + Semiring] Obj_func::from_array(
  obj_type : String,
  arr : Array[V],
  vars : Array[Variable],
) -> Obj_func[V] {
  Obj_func::new(obj_type).set_poly(Poly::from_var_array(arr, vars))
}

///|
pub fn[V : Eq + Semiring + Zero + Neg] Obj_func::to_min(
  self : Obj_func[V],
) -> Obj_func[V] {
  match self.sense {
    Minimize => self
    Maximize => { sense: Minimize, obj_poly: -self.obj_poly }
  }
}

///|
pub fn[V : Zero] Obj_func::to_vector(
  self : Obj_func[V],
  var_num : Int,
) -> Array[V] {
  let res = self.obj_poly.to_array()
  while res.length() <= var_num {
    res.push(V::zero())
  }
  res
}

///|
pub fn[V] judge_max(self : Obj_func[V]) -> Bool {
  match self.sense {
    Maximize => true
    Minimize => false
  }
}

///|
test "show" {
  let x1 : Variable = { name: "x1", low_bound: -1.0, up_bound: 1.0 }
  let x2 : Variable = { name: "x2", low_bound: -1.0, up_bound: 1.0 }
  let x3 : Variable = { name: "x3", low_bound: -1.0, up_bound: 1.0 }
  let poly = Poly::new()
  poly.add_term_inplace(x1, 3.5)
  poly.add_term_inplace(x2, 1.5)
  poly.add_term_inplace(x3, -2)
  let obj_func = Obj_func::new("max").set_poly(poly)
  inspect(obj_func, content="max  3.5x1 + 1.5x2 + -2x3")
  inspect(obj_func.to_min(), content="min  -3.5x1 + -1.5x2 + 2x3")
}
