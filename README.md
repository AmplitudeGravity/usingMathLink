# usingMathLink
It convert the MathLink output to Julia function and symengine function. 
The functions are used to in Cuba which is a numerical integration package.
It depends on the following packages: SymEngine MathLink SyntaxTree, SpecialFunctions


Example: define the mathlink symbol for variable or mathematica functions
```julia
   using UseMathLink, MathLink
   @wvar Solve Flatten #import the mathematica function 当心函数重名
   @wvars c 2
   sol=Solve((c1+0.2+0.2im==0,c1+(-1)*c2+0.1==0),(c1,c2))|>weval|>Flatten|>weval|>math2Expr
```
The output result is 
```julia
   2-element Array{Expr,1}:
 :(Rule(c1, Complex(-0.2, -0.2)))
 :(Rule(c2, Complex(-0.1, -0.2)))
```


```julia 
math2Expr("OutPut of MathLink")
``` 
transform the mathematica Expression to Julia Expr

```julia 
expr2fun("Julia Expr") 
``` 
transform the Julia Expr to a julia function. This function is used in the CUBA.

```julia 
math2symEngine("OutPut of MathLink")
``` 
transform the mathematica Expreesion to symEngine function. To get julia function, you can use the lambdify function in SymEngine.

```julia 
lambdify(math2symEngine("OutPut of MathLink"),(symbol variables))
```

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

define the symbol variables by the macro 
```julia
@jvars x 3 3 3
@jvars x 16
@jvar x1 x2 x3 y4
```



