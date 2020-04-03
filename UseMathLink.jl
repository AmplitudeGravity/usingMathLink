module UseMathLink

using SymEngine
using MathLink
export math2symEngine, math2Expr, evalSym, Power

function math2symEngine(symb::MathLink.WSymbol)
    SymEngine.symbols(symb.name)
end

function math2symEngine(num::Number)
    num
end
function math2symEngine(expr::MathLink.WExpr)
    if expr.head.name=="Times"
        return *(map(math2symEngine,expr.args)...)
    elseif expr.head.name=="Plus"
        return +(map(math2symEngine,expr.args)...)
    elseif expr.head.name=="Power"
        return ^(map(math2symEngine,expr.args)...)
    elseif expr.head.name=="Rational"
        return  //(map(math2symEngine,expr.args)...)
    else
        return SymEngine.SymFunction(expr.head.name)(map(math2symEngine,expr.args)...)
    end
end
#Mathematica to julia expr
function math2Expr(symb::MathLink.WSymbol)
    Symbol(symb.name)
end
function math2Expr(num::Number)
    num
end
function math2Expr(expr::MathLink.WExpr)
    if expr.head.name=="Times"
        return Expr(:call, :*, map(math2Expr,expr.args)...)
    elseif expr.head.name=="Plus"
        return Expr(:call, :+,map(math2Expr,expr.args)...)
    elseif expr.head.name=="Power"
        return Expr(:call, :Power, map(math2Expr,expr.args)...)
    elseif expr.head.name=="Rational"
        return  Expr(:call, ://, map(math2Expr,expr.args)...)
    else
        return Expr(:call, Symbol(expr.head.name), map(math2Expr,expr.args)...)
    end
end

function evalSym(ex::SymEngine.Basic)
    fn = SymEngine.get_symengine_class(ex)
    if fn == :FunctionSymbol
        as=get_args(ex)
        return Expr(:call, Symbol(get_name(ex)), [evalSym(a) for a in as]...)|>eval
    elseif fn == :Symbol
        return Symbol(SymEngine.toString(ex))|>eval
    elseif (fn in SymEngine.number_types) || (fn == :Constant)
        return N(ex)|>eval
    elseif fn==:Mul
        as=get_args(ex)
        return *([evalSym(a) for a in as]...)
    elseif fn==:Add
        as=get_args(ex)
        return +([evalSym(a) for a in as]...)
    elseif fn==:Pow
        as=get_args(ex)
        return ^([evalSym(a) for a in as]...)
    elseif fn==:Rational
        as=get_args(ex)
        return //([evalSym(a) for a in as]...)
    end
end

function Power(f::T1,g::T2) where {T1 <: Union{Int, Int64, Float32, Float64,Complex{Float64}},T2 <: Union{Int, Int64, Float32, Float64, Complex{Float64}}}
 fc=Complex(f);
   if imag(fc)==0.0
       fc=real(fc)+0.0im
   end
 fc^g
end

#replace of the symbols in an expression
function rep!(e, old, new)
   for (i,a) in enumerate(e.args)
       if a==old
           e.args[i] = new
       elseif a isa Expr
           rep!(a, old, new)
       end
       ## otherwise do nothing
   end
   e
end

#print(Power(-0.8+0.0im,-0.3))

end
