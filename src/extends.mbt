///|
pub extend Variable with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Variable with Eq::{not_equal}

///|
pub extend Variable with Compare::{compare}

///|
#deprecated("Use `<`, `<=`, `>`, `>=` instead", skip_current_package=true)
#doc(hidden)
pub extend Variable with Compare::{op_lt, op_le, op_gt, op_ge}

///|
pub extend Variable with Show::{to_string}

///|
#deprecated("Use `to_string` or `\"\\{x}\"` instead", skip_current_package=true)
#doc(hidden)
pub extend Variable with Show::{output}

///|
pub extend Variable with One::{one}

///|
pub extend Poly with Eq::{equal}

///|
#deprecated("Use `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Poly with Eq::{not_equal}

///|
pub extend Poly with Neg::{neg}

///|
pub extend Poly with Show::{to_string}

///|
#deprecated("Use `to_string` or `\"\\{x}\"` instead", skip_current_package=true)
#doc(hidden)
pub extend Poly with Show::{output}

///|
pub extend Obj_func with Show::{to_string}

///|
#deprecated("Use `to_string` or `\"\\{x}\"` instead", skip_current_package=true)
#doc(hidden)
pub extend Obj_func with Show::{output}

///|
pub extend Constraint with Show::{to_string}

///|
#deprecated("Use `to_string` or `\"\\{x}\"` instead", skip_current_package=true)
#doc(hidden)
pub extend Constraint with Show::{output}

///|
pub extend Lp with Show::{to_string}

///|
#deprecated("Use `to_string` or `\"\\{x}\"` instead", skip_current_package=true)
#doc(hidden)
pub extend Lp with Show::{output}
