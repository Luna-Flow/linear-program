///|
using @lg {trait One, trait Zero, trait Semiring}

///|
using @la {type Matrix}

///|
/// "Approximately zero" interface: 
/// Any type implementing it can determine whether it is approximately equal to 0
pub trait ApproximatelyZero {
  /// Determine whether the value is approximately zero
  fn is_zero_eps(Self) -> Bool
}

///|
pub impl ApproximatelyZero for Int with fn is_zero_eps(x) {
  x == 0
}

///|
pub impl ApproximatelyZero for Double with fn is_zero_eps(x) {
  if x < 0.0 {
    x > -1.0e-15
  } else {
    x < 1.0e-15
  }
}
