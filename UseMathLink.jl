module UseMathLink

using SymEngine
using MathLink
using SyntaxTree, SpecialFunctions
export math2symEngine, math2Expr, evalSym, Power, expr2fun, List, @varj, @varjs, remove!, ObFunctor
export wedge, Length
macro expr2fun(expr,args)
    :($(Expr(:tuple,args.args...))->$expr)
end
expr2fun(expr,args) = :(@expr2fun $expr [$(args...)]) |> eval


mutable struct  ObFunctor  #transform to the functior for a given function (方便但慢一些)
    name::String
    numvar::Int
    ObFunctor(name,numvar)=new(name,numvar)
end
function (odF::ObFunctor)(args...)
    if length(args)==odF.numvar
        getfield(Main, Symbol(odF.name))(args...)
    else
        print("wrong args")
    end
end
#define the symbol variables Expr(:quote, s) Expr(:quote,Symbol("$x$i"))

macro varj(x...)
    vars=Expr(:block)
    for s in x
        push!(vars.args, Expr(:(=), esc(s), Expr(:call, Symbol, Expr(:quote, s))))
    end
    push!(vars.args, Expr(:tuple, map(esc, x)...))
    vars
end

macro varjs(x, j::Int64)
    vars=Expr(:block)
    for i = 1:j
        push!(vars.args, Expr(:(=), esc(Symbol("$x$i")), Expr(:quote,Symbol("$x$i"))))
    end
    push!(vars.args,  Expr(:tuple,map(esc, "$x".*map(string,1:j).|>Symbol)...))
    vars
end

#remove an item in the list
function remove!(list, item)
    deleteat!([list...], findall(x->x==item, list))
end
function math2symEngine(symb::MathLink.WSymbol)
    SymEngine.symbols(symb.name)
end

function math2symEngine(num::Number)
    num
end

binanyOPSymEngine=Dict("Times" => *,"Plus"=> +,"Power"=>^,"Rational"=>//)
function math2symEngine(expr::MathLink.WExpr)
    haskey(binanyOPSymEngine,expr.head.name) ? op=binanyOPSymEngine[expr.head.name] : op=SymFunction(expr.head.name)
    if expr.head.name=="List"
        return List(map(math2symEngine,expr.args)...)
    else
        #return Expr(:call, Symbol(expr.head.name), map(math2symEngine,expr.args)...)|>eval
        return op(map(math2symEngine,expr.args)...)
    end
end
#Mathematica to julia expr
function math2Expr(symb::MathLink.WSymbol)
    Symbol(symb.name)
end
function math2Expr(num::Number)
    num
end
binanyOPSymbol=Dict("Times" => :*,"Plus"=> :+,"Rational"=>://)
function math2Expr(expr::MathLink.WExpr)
    haskey(binanyOPSymbol,expr.head.name) ? op=binanyOPSymbol[expr.head.name] : op=Symbol(expr.head.name)
    if  expr.head.name=="List"
        return  List(map(math2Expr,expr.args)...)
    else
        return Expr(:call, op, map(math2Expr,expr.args)...)
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

function Power(f::T1,g::T2) where {T1 <: Union{Irrational,Int, Int64, Float32, Float64,Complex{Float64}},T2 <: Union{Irrational,Int, Int64, Float32, Float64, Complex{Float64}}}
    typeof(f)==Complex{Float64} ? fc=f : fc=Complex(f,0)
   if imag(fc)==0.0
       fc=real(fc)+0.0im
   end
 fc^g
end

function List(args...)
 [args...]
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

function wedge(args...)
    args
end
function Length(f::Expr)
    length(f.args)-1
end
#Power(pi+0.0im,-0.3)
Power(ℯ,-0.2)
#@varj x1 x2
end
