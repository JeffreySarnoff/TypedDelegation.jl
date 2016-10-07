doc"""
This package offers macros that delegate functions over one or more fields of a type;      
and macros that delegate operations through fields to return a value of the same type.

**exports**

        @delegate_oneField,                       #     apply functions over field   
        @delegate_oneField_fromTwoVars,           #          (return type from func)    
        @delegate_oneField_asType,                #     and reobtain the same type   
        @delegate_oneField_fromTwoVars_asType,    #          (return type from args)   
                                                  #
        @delegate_twoFields,                      #     apply functions over fields   
        @delegate_twoFields_fromTwoVars,          #          (return type from func)    
        @delegate_twoFields_asType,               #     and reobtain the same type   
        @delegate_twoFields_fromTwoVars_asType    #          (return type from args)   
                                                  #
        @delegate_threeFields,                    #     apply functions over fields
        @delegate_threeFields_fromTwoVars,        #          (return type from func) 
        @delegate_threeFields_asType,             #     and reobtain the same type
        @delegate_threeFields_fromTwoVars_asType  #          (return type from args)
"""
module TypedDelegation

export @delegate_oneField,                       #     apply functions over field
       @delegate_oneField_fromTwoVars,           #          (return type from func) 
       @delegate_oneField_asType,                #     and reobtain the same type
       @delegate_oneField_fromTwoVars_asType,    #          (return type from args)
                                                 #
       @delegate_twoFields,                      #     apply functions over fields
       @delegate_twoFields_fromTwoVars,          #          (return type from func) 
       @delegate_twoFields_asType,               #     and reobtain the same type
       @delegate_twoFields_fromTwoVars_asType,   #          (return type from args)
                                                 #
       @delegate_threeFields,                    #     apply functions over fields
       @delegate_threeFields_fromTwoVars,        #          (return type from func) 
       @delegate_threeFields_asType,             #     and reobtain the same type
       @delegate_threeFields_fromTwoVars_asType  #          (return type from args)


#=
»      internal macros, compositable
=#

"""
@fieldtypes( aType ) works like aType.types
"""
macro fieldtypes( aType )
    esc( :( getfield( $aType, :types ) ) )
end 

"""
@fieldsyms( aType ) works like fieldnames(aType)
"""
macro fieldsyms( aType )
    esc( :( fieldnames( $aType ) ) )
end 

"""
@fieldstrs aType ) yields the string forms of the fields in aType
"""
macro fieldstrs( aType )
    return quote
        local syms = @fieldsyms( ($aType) )
        local strs = map(string, syms)
        strs
    end
end

"""
@getfield( varOfType, symFieldOfType ) works like getfield(varOfType, symFieldOfType)
"""
macro getfield( varOfType, symFieldOfType)
    esc( :( getfield( ($varOfType), ($symFieldOfType) )) )
end

"""
@getfields( varOfType ) yields a tuple of field values for varOfType (in order)
"""
macro getfields( varOfType )
    return quote
        local syms = @fieldsyms( typeof( $varOfType ) ) 
        local vals = Vector( 0 )
        for item in syms
            push!( vals, @getfield( $varOfType, item ) )
        end
        (vals...)
    end
end


"""
@fieldvalues( varOfType ) yields the values of the fields in varOfType (in order)
"""
macro fieldvalues( varOfType )
    esc( :( @getfields( $varOfType ) ) )
end

"""
@fieldvalues( varOfType, nFields ) yields thethe values of the first nFields declared in Type (in order)
"""
macro fieldvalues( varOfType, nFields )
    return quote
        local allvals = @fieldvalues( $varOfType )
        local vals = allvals[1:$nFields]
        vals
    end
end    
        


#=
»      delegation using one field of a type   
=#


#=
»»         versions for use when the result type differs from the type of the params
=#


doc"""
@delegate_oneField(sourceType, sourceField, targetedFuncs)
This returns a value of same types as the `targetedFuncs` result types.

    import Base: string, show

    immutable MyInt16
      value::Int16
    end

    @delegate_oneField( MyInt16, value, [string, show]);

    three = MyInt16(3);
    seven = MyInt16(7);

    string(three) == "3"           # true
    show(seven)                    # 7
"""
macro delegate_oneField(sourceType, sourceField, targetedFuncs)
  typesname  = esc( :($sourceType) )
  fieldname = esc(Expr(:quote, sourceField))
  funcnames  = targetedFuncs.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), args...) = 
                   ($funcname)(getfield(a,($fieldname)), args...)
               end
    end
  return Expr(:block, fdefs...)
end


doc"""
@delegate_oneField_fromTwoVars(sourceType, sourceField, targetedOps)
This returns a value of same types as the `targetedOps` result types.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)

    import Base: (<), (<=)

    immutable MyInt16  
      value::Int16  
    end;

    @delegate_oneField_fromTwoVars( MyInt16, value, [ (<), (<=) ] );

    three = MyInt16(3);
    seven = MyInt16(7);

    three <  seven                 # true
    seven <= three                 # false
"""
macro delegate_oneField_fromTwoVars(sourceType, sourceField, targetedFuncs)
  typesname  = esc( :($sourceType) )
  fieldname = esc(Expr(:quote, sourceField))
  funcnames  = targetedFuncs.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), b::($typesname), args...) =
                   ($funcname)(getfield(a,($fieldname)), 
                               getfield(b,($fieldname)), args...)
               end
    end
  return Expr(:block, fdefs...)
end



#=
»       versions for use when the result has the same type as the params
=#


doc"""
@delegate_oneField_asType(sourceType, sourceField, targetedFuncs)
This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: abs, (-)

    immutable MyInt16
      value::Int16
    end

    @delegate_oneField_asType( MyInt16, value, [abs, (-)]);

    three = MyInt16(3);
    seven = MyInt16(7);

    abs(three) == three            # true
    -(seven) === MyInt16(-7)       # true

"""
macro delegate_oneField_asType(sourceType, sourceField, targetedOps)
  typesname  = esc( :($sourceType) )
  fieldname = esc(Expr(:quote, sourceField))
  funcnames  = targetedOps.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), args...) =
                   ($typesname)( ($funcname)(getfield(a,($fieldname)), args...) )
               end
    end
  return Expr(:block, fdefs...)
end


doc"""
@delegate_oneField_fromTwoVars_asType(sourceType, sourceField, targetedOps)
This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: (+), (-), (*)

    type 
      value::Int16
    end

    @delegate_oneField_fromTwoVars_asType( MyInt16, value, [ (+), (*) ] );

    three = MyInt16(3);
    seven = MyInt16(7);

    three + seven == MyInt16(3+7)  # true
    three * seven == MyInt16(3*7)  # true

"""
macro delegate_oneField_fromTwoVars_asType(sourceType, sourceField, targetedOps)
  typesname  = esc( :($sourceType) )
  fieldname = esc(Expr(:quote, sourceField))
  funcnames  = targetedOps.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), b::($typesname), args...) =
                   ($typesname)( ($funcname)(getfield(a,($fieldname)), 
                                             getfield(b,($fieldname)), args...) )
               end
    end
  return Expr(:block, fdefs...)
end



#=
»      delegation using two fields of a type   
=#


#=
»»        versions for use when the result type differs from the type of the params
=#

doc"""
@delegate_twoFields(sourceType, firstField, secondField, targetedFuncs)
This returns a value of same types as the `targetedFuncs` result types.

    import Base: hypot
    
    immutable RightTriangle
      legA::Float64
      legB::Float64  
    end;

    @delegate_twoFields( RightTriangle, legA, legB, [ hypot, ] );
  
    myRightTriangle  = RightTriangle( 3.0, 4.0 );
    hypot(myRightTriangle)   #  5.0

"""     
macro delegate_twoFields(sourceType, firstField, secondField, targetedFuncs)
  typesname  = esc( :($sourceType) )
  field1name = esc(Expr(:quote, firstField))
  field2name = esc(Expr(:quote, secondField))
  funcnames  = targetedFuncs.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), args...) = 
                   ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), args...)
               end
    end
  return Expr(:block, fdefs...)
end


#=
»»        versions for use when the result has the same type as the params
=#

doc"""
@delegate_twoFields_asType(sourceType, firstField, secondField, targetedOps)
This returns a value of the same type as the `sourceType` by rewrapping the result.

    function renormalize(a::Float64, b::Float64)
      hi = a + b
      t = hi - a
      lo = (a - (hi - t)) + (b - t)
      return hi, lo
    end

    immutable HiLo  
      hi::Float64
      lo::Float64   
    end;
    
    @delegate_twoFields_asType( HiLo, hi, lo, [ renormalize, ] );

    myHiLo = renormalize( HiLo(12.555555555, 8000.333333333) ); 
    showall(myHiLo)     # HiLo(8012.888888888,4.440892098500626e-14)

"""
macro delegate_twoFields_asType(sourceType, firstField, secondField, targetedOps)
  typesname  = esc( :($sourceType) )
  field1name = esc(Expr(:quote, firstField))
  field2name = esc(Expr(:quote, secondField))
  funcnames  = targetedOps.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), args...) = 
                    ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), args...)... )
               end
    end
  return Expr(:block, fdefs...)
end


doc"""
@delegate_twoFields_fromTwoVars(sourceType, firstField, secondField, targetedFuncs)
This returns a value of same types as the `targetedFuncs` result types.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)    
  that evalutes two fields of `TheType` from arg1 and also from arg2.
      result = targetedFunc( arg1.firstField, arg1.secondField,  
                             arg2.firstField, arg2.secondField )

    import Base: mean

    type MyInterval
      lo::Float64
      hi::Float64
    
      function MyInterval(lo::Float64, hi::Float64)
         mn, mx = ifelse( hi<lo, (hi, lo), (lo, hi) )
         new( mn, mx )
      end   
    end;

    MyInterval{T<:AbstractFloat}(lo::T, hi::T) =
        MyInterval( Float64(lo), Float64(hi) )

    @delegate_twoFields_fromTwoVars( MyInterval, lo, hi, [ mean, ])

    function mean( x::MyInterval )
        return x.lo * 0.5 + x.hi * 0.5
    end
    function mean{T<:MyInterval}( a::T, b::T )
        return mean( a ) * 0.5 + mean( b ) * 0.5
    end

    one_three = MyInterval(1, 3);
    two_four  = MyInterval(2, 4);

    mean( one_three, two_four ) == 2.5 # true
"""
macro delegate_twoFields_fromTwoVars(sourceType, firstField, secondField, targetedFuncs)
  typesname  = esc( :($sourceType) )
  field1name = esc(Expr(:quote, firstField))
  field2name = esc(Expr(:quote, secondField))
  funcnames  = targetedFuncs.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), b::($typesname), args...) = 
                     ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)),
                                 getfield(b, ($field1name)), getfield(b, ($field2name)), 
                                 args...)
               end
    end
  return Expr(:block, fdefs...)
end


doc"""
@delegate_twoFields_fromTwoVars_asType(sourceType, firstField, secondField, targetedFuncs)
This returns a value of the same type as the `sourceType` by rewrapping the result.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)    
  that evalutes two fields of `TheType` from arg1 and also from arg2
  and applies itself over them, obtaining field_values for constructive
  generation of the result; a new realization of TheType( field_values... ).

      TheType( targetedFunc( arg1.firstField, arg1.secondField,  
                             arg2.firstField, arg2.secondField )... )

    import Base: union, intersect

    type MyInterval
      lo::Float64
      hi::Float64
    
      function MyInterval(lo::Float64, hi::Float64)
         mn, mx = ifelse( hi<lo, (hi, lo), (lo, hi) )
         new( mn, mx )
      end   
    end;

    MyInterval{T<:AbstractFloat}(lo::T, hi::T) =
        MyInterval( Float64(lo), Float64(hi) )

    @delegate_twoFields_fromTwoVars_asType( MyInterval, lo, hi, [ union, ])

    function union{T<:MyInterval}( a::T, b::T )
        lo = min( a.lo, b.lo )
        hi = max( a.hi, b.hi )
        return T( lo, hi )
    end

    one_three = MyInterval(1, 3);
    two_four  = MyInterval(2, 4);

    union( one_three, two_four ) == MyInterval(1, 4) # true
"""
macro delegate_twoFields_fromTwoVars_asType(sourceType, firstField, secondField, targetedOps)
  typesname  = esc( :($sourceType) )
  field1name = esc(Expr(:quote, firstField))
  field2name = esc(Expr(:quote, secondField))
  funcnames  = targetedOps.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), b::($typesname), args...) = 
                    ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)),
                                              getfield(b, ($field1name)), getfield(b, ($field2name)), 
                                              args...)... )
               end
    end
  return Expr(:block, fdefs...)
end


#=
»      delegation using three fields of a type   
=#


#=
»»        versions for use when the result type differs from the type of the params
=#

doc"""
@delegate_threeFields(sourceType, firstField, secondField, targetedFuncs)
This returns a value of same types as the `targetedFuncs` result types.

    import Base: norm 

    norm{R<:Real}(xs::Vararg{R,3}) = norm([xs...])
    
    immutable XYZ
      x::Float64
      y::Float64
      z::Float64
    end;

    @delegate_threeFields( XYZ, x, y, z, [ norm, ] );
  
    pointA  = XYZ( 3.0, 4.0, 5.0 );
    norm(pointA)   #  7.0710678+

"""     
macro delegate_threeFields(sourceType, firstField, secondField, thirdField, targetedFuncs)
  typesname  = esc( :($sourceType) )
  field1name = esc(Expr(:quote, firstField))
  field2name = esc(Expr(:quote, secondField))
  field3name = esc(Expr(:quote, thirdField))
  funcnames  = targetedFuncs.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), args...) = 
                   ($funcname)(getfield(a, ($field1name)), 
                               getfield(a, ($field2name)), 
                               getfield(a, ($field3name)), args...)
               end
    end
  return Expr(:block, fdefs...)
end


#=
»»        versions for use when the result has the same type as the params
=#

doc"""
@delegate_threeFields_asType(sourceType, firstField, secondField, targetedOps)
This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: normalize

    normalize{R<:Real}(xs::Vararg{R,3}) = normalize([xs...])

    immutable XYZ
      x::Float64
      y::Float64
      z::Float64
    end;

    @delegate_threeFields_asType( XYZ, x, y, z, [ normalize, ] );
    
    pointA  = XYZ( 3.0, 4.0, 5.0 );
    normalize(pointA)   #  XYZ( 0.424264+, 0.565685+, 0.707107- )
"""
macro delegate_threeFields_asType(sourceType, firstField, secondField, thirdField, targetedOps)
  typesname  = esc( :($sourceType) )
  field1name = esc(Expr(:quote, firstField))
  field2name = esc(Expr(:quote, secondField))
  field3name = esc(Expr(:quote, thirdField))
  funcnames  = targetedOps.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), args...) = 
                    ($typesname)( ($funcname)(getfield(a, ($field1name)), 
                                              getfield(a, ($field2name)),
                                              getfield(a, ($field3name)), args...)... )
               end
    end
  return Expr(:block, fdefs...)
end


doc"""
@delegate_threeFields_fromTwoVars(sourceType, firstField, secondField, thirdField, targetedFuncs)
This returns a value of same types as the `targetedFuncs` result types.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)    
  that evalutes three fields of `TheType` from arg1 and also from arg2.
      result = targetedFunc( arg1.firstField, arg1.secondField, arg1.thirdField,  
                             arg2.firstField, arg2.secondField, arg2.thirdField )

    import Base: norm, normalize, cross, sin

    normalize{R<:Real}(xs::Vararg{R,3}) = normalize([xs...])

    cross{R<:Real}(xs::Vararg{R,6}) = cross([xs[1:3]...], [xs[4:6]...])


    immutable XYZ
      x::Float64
      y::Float64
      z::Float64
    end;


    @delegate_threeFields_asType( XYZ, x, y, z, [ normalize, ] );
    @delegate_threeFields_fromTwoVars( XYZ, x, y, z, [ cross, ] );

    function sin( pointA::XYZ, pointB::XYZ )
        norm( cross( normalize(pointA), normalize(pointB) ) )
    end
    
    pointA  = XYZ( 3.0, 4.0, 5.0 );
    pointB  = XYZ( 5.0, 4.0, 3.0 );

    sin(pointA, pointB) #  0.391918+
"""
macro delegate_threeFields_fromTwoVars(sourceType, firstField, secondField, thirdField, targetedFuncs)
  typesname  = esc( :($sourceType) )
  field1name = esc(Expr(:quote, firstField))
  field2name = esc(Expr(:quote, secondField))
  field3name = esc(Expr(:quote, thirdField))
  funcnames  = targetedFuncs.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), b::($typesname), args...) = 
                     ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), getfield(a, ($field3name)),
                                 getfield(b, ($field1name)), getfield(b, ($field2name)), getfield(b, ($field3name)),
                                 args...)
               end
    end
  return Expr(:block, fdefs...)
end


doc"""
@delegate_threeFields_fromTwoVars_asType(sourceType, firstField, secondField, thirdField, targetedOps)
This returns a value of the same type as the `sourceType` by rewrapping the result.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)    
  that evalutes three fields of `TheType` from arg1 and also from arg2
  and applies itself over them, obtaining field_values for constructive
  generation of the result; a new realization of TheType( field_values... ).

      TheType( targetedFunc( arg1.firstField, arg1.secondField, arg1.thirdField, 
                             arg2.firstField, arg2.secondField, arg2.thirdField )... )


    import Base: cross

    cross{R<:Real}(xs::Vararg{R,6}) = cross([xs[1:3]...], [xs[4:6]...])


    immutable XYZ
      x::Float64
      y::Float64
      z::Float64
    end;


    @delegate_threeFields_fromTwoVars_asType( XYZ, x, y, z, [ cross, ] );

    
    pointA  = XYZ( 3.0, 4.0, 5.0 );
    pointB  = XYZ( 5.0, 4.0, 3.0 );

    cross(pointA, pointB) #  XYZ(-8.0, 16.0, -8.0)
"""
macro delegate_threeFields_fromTwoVars_asType(sourceType, firstField, secondField,  thirdField, targetedOps)
  typesname  = esc( :($sourceType) )
  field1name = esc(Expr(:quote, firstField))
  field2name = esc(Expr(:quote, secondField))
  field3name = esc(Expr(:quote, thirdField))
  funcnames  = targetedOps.args
  n = length(funcnames)
  fdefs = Array(Any, n)
  for i in 1:n
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(a::($typesname), b::($typesname), args...) = 
                     ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), getfield(a, ($field3name)),
                                               getfield(b, ($field1name)), getfield(b, ($field2name)), getfield(b, ($field3name)),
                                               args...)... )
               end
    end
  return Expr(:block, fdefs...)
end

#=
# ~~~~~~~~
=#

#=
    earlier implementations

    description and logic from John Myles White
        <https://gist.github.com/johnmyleswhite/5225361>

    additional macro work from DataStructures.jl
        <https://github.com/JuliaLang/DataStructures.jl/blob/master/src/delegate.jl?

    and delegation with n-ary ops from Toivo Henningsson
        <https://groups.google.com/forum/#!msg/julia-dev/MV7lYRgAcB0/-tS50TreaPoJ?
=#

end # module TypedDelegation
