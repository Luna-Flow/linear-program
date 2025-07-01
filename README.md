A Moonbit library for defining and solving linear programming problems

/** how to define a linear-program */
1. define variables_array  
   format: (name : String, low_bound : Double, up_bound : Double)  
2. define object_func  
   use interface: Obj_func::from_array(function_type : String, coeff_array : Array[V], variables_array)  
3. define eq_constraint  
   format: (coeff_array : Array[V], b_value : Array[V])  
4. define ineq_constraint  
   format: (coeff_array : Array[V], label : String, b_value : Array[V])  
5. define linear-program  
   Use interface:  
   Lp::new(object_func, variables_array)
     .cons_from_Array(eq_array = eq_constraint, ineq_array = ineq_constraint)

```moonbit
let vars = [
  Variable::new("x1", 0.0, @double.max_value),
  Variable::new("x2", 0.0, @double.max_value),
  Variable::new("x3", 0.0, @double.max_value),
  Variable::new("x4", 0.0, @double.max_value),
]

let matrix = Matrix::from_2d_array([
  [1, 2, 3, 4, 0],
  [4, 1, 0, 6, 1],
  [1, 3, 1, 0, 0],
  [-1, 4, 7, 1, 2]
])

let lp = Lp::from_matrix(matrix, vars, "min")
