module UseMathLink

using SymEngine
using MathLink
using SyntaxTree
export math2symEngine, math2Expr, evalSym, genfun
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
        return Expr(:call, :^, map(math2Expr,expr.args)...)
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

#from the Julia expression to Julia function
macro genfun(expr,args)
    :($(Expr(:tuple,args.args...))->$expr)
end
genfun(expr,args) = :(@genfun $expr [$(args...)]) |> eval

end
