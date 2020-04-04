# usingMathLink
It convert the MathLink output to Julia function and symengine function. 
The functions are used to in Cuba which is a numerical integration package.
It depends on the following packages: SymEngine MathLink SyntaxTree, SpecialFunctions

math2Expr() is transform the mathematica Expression to Julia Expr

expr2fun() is transform the Julia Expr to a julia function. This function is used in the CUBA.

Power() function to replace the power function ^ in Julia. The fraction power fucntion is fix to the canonical branch.
```julia
Power(-2-0.0im,-0.2)
0.7042902001692478 - 0.5116967824803669im
```

