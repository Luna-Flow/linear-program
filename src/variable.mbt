///|
struct Variable {
  name : String
  low_bound : Double
  up_bound : Double
}

///|
pub impl Show for Variable with fn to_string(self) -> String {
  self.name
}

///|
pub impl Show for Variable with fn output(self, logger) -> Unit {
  logger.write_string(self.name)
}

///|
pub impl One for Variable with fn one() -> Variable {
  { name: "", low_bound: @double.min_value, up_bound: @double.max_value, }
}

///|
pub impl Compare for Variable with fn compare(self, other) -> Int {
  self.name.compare(other.name)
}

///|
pub impl Eq for Variable with fn equal(self, other) -> Bool {
  self.name == other.name
}

///|
pub fn Variable::new(n : String, l : Double, u : Double) -> Variable {
  { name: n, low_bound: l, up_bound: u, }
}

///|
pub fn Variable::show_all(self : Variable) -> String {
  self.name + " : [\{self.low_bound}, \{self.up_bound}]"
}
