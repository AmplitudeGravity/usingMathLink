# usingMathLink
It convert the MathLink output to Julia function and symengine function. 
The functions are used to in Cuba which is a numerical integration package.
It depends on the following packages: SymEngine MathLink SyntaxTree, SpecialFunctions

```math2Expr("OutPut of MathLink")``` transform the mathematica Expression to Julia Expr

```expr2fun("Julia Expr") ``` transform the Julia Expr to a julia function. This function is used in the CUBA.

```math2symEngine("OutPut of MathLink")``` transform the mathematica Expreesion to symEngine function. To get julia function, you can use the lambdify function in SymEngine.

```lambdify(math2symEngine("OutPut of MathLink"),(symbol variables)) ```

To get value of the symEngine function, you can also use the evalSym() function
```julia
       MLExpr=W`List[polygamma[n,x],gamma[y],gamma[z]]`|>weval
       SEExpr=math2symEngine(MLExpr)
       @vars n x y
       subs(SEExpr[1],n=>2,x=>0.2)|>evalSym
       -251.47803611443592
 ```

Add the OPFunctor: it can transform a function into an Funtor
```julia
    ObFunctor("function name", variable numbers)
```

```Power()``` function to replace the power function ^ in Julia. The fraction Power fucntion is fixed to the canonical branch.
```julia
Power(-2-0.0im,-0.2)
0.7042902001692478 - 0.5116967824803669im
```

