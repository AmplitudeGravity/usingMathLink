module UseMathLink

using SymEngine
using MathLink
using SpecialFunctions
export math2symEngine, math2Expr, evalSym, Power, expr2fun, List # @vars
export wedge, Length, remove!, ObFunctor, rep!
export @wvar, @wvars, @jvarj, @jvars
macro expr2fun(expr,args) #This is genfun in SyntaxTree.jl by @chakravala
    :($(Expr(:tuple,args.args...))->$expr)
end
expr2fun(expr,args) = :(@expr2fun $expr [$(args...)]) |> eval

import Base: +,  ^,  //, *, ==
function ==(w1::T1, w2::T2) where {T1<:Union{MathLink.WSymbol,MathLink.WExpr,Number}, T2<: Union{MathLink.WSymbol,MathLink.WExpr,Number}}
     W"Equal"(w1,w2)
end
for (op, binarymethod) in ((:+, W"Plus"), (:*, W"Times"),  (://, W"Rational"), (:^, W"Power"))
    @eval begin
        ($op)(w1::T1, w2::T2) where {T1<:Union{MathLink.WSymbol,MathLink.WExpr}, T2<: Union{MathLink.WSymbol,MathLink.WExpr}}= ($binarymethod)(w1,w2)
        ($op)(w1::T1, w2::Number) where {T1<:Union{MathLink.WSymbol,MathLink.WExpr}}= ($binarymethod)(w1,w2)
        ($op)(w1::Number, w2::T2) where {T2<:Union{MathLink.WSymbol,MathLink.WExpr}}= ($binarymethod)(w1,w2)
        ($op)(w1::Complex, w2::T2) where {T2<:Union{MathLink.WSymbol,MathLink.WExpr}}= ($binarymethod)(W"Complex"(real(w1),imag(w1)),w2)
        ($op)(w1::T1, w2::Complex) where {T1<:Union{MathLink.WSymbol,MathLink.WExpr}}= ($binarymethod)(w1,W"Complex"(real(w2),imag(w2)))
    end
end


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
#define the symbol variables
#=
macro vars(x,n::Int64)
    q=Expr(:block)
    for i = 1:n
        push!(q.args, Expr(:(=), esc(Symbol("$x$i")), Expr(:call, :(SymEngine._symbol), Expr(:quote, Symbol("$x$i")))))
    end
    push!(q.args, Expr(:tuple, map(esc, "$x".*map(string,1:n).|>Symbol)...))
    q
end
=#
macro wvar(x...)
    vars=Expr(:block)
    for s in x
        push!(vars.args, Expr(:(=), esc(s), Expr(:call, MathLink.WSymbol, Expr(:quote, s))))
    end
    push!(vars.args, Expr(:tuple, map(esc, x)...))
    vars
end
macro wvars(x, j::Int64)
    vars=Expr(:block)
    for i = 1:j
        push!(vars.args, Expr(:(=), esc(Symbol("$x$i")), Expr(:quote,MathLink.WSymbol("$x$i"))))
    end
    push!(vars.args,  Expr(:tuple,map(esc, "$x".*map(string,1:j).|>MathLink.WSymbol)...))
    vars
end

macro wvars(x, j...)
    vars=Expr(:block)
    for i in Iterators.product((1:k for k in j)...)
        push!(vars.args, Expr(:(=), esc(Symbol("$x$(i...)")), Expr(:quote,MathLink.WSymbol("$x$(i...)"))))
    end
    push!(vars.args,  Expr(:tuple,map(esc, "$x".*map(string,["$(i...)" for i in Iterators.product((1:k for k in j)...) ]).|>MathLink.WSymbol)...))
    vars
end

macro jvar(x...)
    vars=Expr(:block)
    for s in x
        push!(vars.args, Expr(:(=), esc(s), Expr(:call, Symbol, Expr(:quote, s))))
    end
    push!(vars.args, Expr(:tuple, map(esc, x)...))
    vars
end

macro jvars(x, j::Int64)
    vars=Expr(:block)
    for i = 1:j
        push!(vars.args, Expr(:(=), esc(Symbol("$x$i")), Expr(:quote,Symbol("$x$i"))))
    end
    push!(vars.args,  Expr(:tuple,map(esc, "$x".*map(string,1:j).|>Symbol)...))
    vars
end

macro jvars(x, j...)
    vars=Expr(:block)
    for i in Iterators.product((1:k for k in j)...)
        push!(vars.args, Expr(:(=), esc(Symbol("$x$(i...)")), Expr(:quote,Symbol("$x$(i...)"))))
    end
    push!(vars.args,  Expr(:tuple,map(esc, "$x".*map(string,["$(i...)" for i in Iterators.product((1:k for k in j)...) ]).|>Symbol)...))
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
Power(0.4-0.0im,-0.2)
#@varj x1 x2
end
