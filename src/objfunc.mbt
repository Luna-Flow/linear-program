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
pub impl[V : Eq + Show + Semiring] Show for Obj_func[V] with to_string(self) -> String {
  match self.sense {
    Minimize => "min  " + self.obj_poly.to_string()
    Maximize => "max  " + self.obj_poly.to_string()
  }
}

///|
pub impl[V : Eq + Show + Semiring] Show for Obj_func[V] with output(self, l) {
  l.write_string(self.to_string())
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
pub fn[V : Eq + Semiring + Compare + Zero] Obj_func::add_term_inplace(
  self : Obj_func[V],
  variable : Variable,
  coeff : V
) -> Unit {
  self.obj_poly.add_term_inplace(variable, coeff)
}

///|
pub fn[V : Eq + Compare + Semiring] Obj_func::from_array(
  obj_type : String,
  arr : Array[V],
  vars : Array[Variable]
) -> Obj_func[V] {
  Obj_func::new(obj_type).set_poly(Poly::from_var_array(arr, vars))
}

///|
pub fn[V : Eq + Semiring + Compare + Zero + Neg] Obj_func::to_min(
  self : Obj_func[V]
) -> Obj_func[V] {
  match self.sense {
    Minimize => self
    Maximize => { sense: Minimize, obj_poly: -self.obj_poly }
  }
}

///|
pub fn[V : Zero] Obj_func::to_vector(
  self : Obj_func[V],
  var_num : Int
) -> Array[V] {
  let res = self.obj_poly.to_Array()
  while res.length() <= var_num {
    res.append([V::zero()])
  }
  res
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
  println(obj_func)
  println(obj_func.to_min())
}
