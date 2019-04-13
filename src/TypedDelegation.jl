"""
This package offers macros that delegate functions over one or more fields of a type;
and macros that delegate operations through fields to return a value of the same type.

**exports**

        @delegate_onefield,                    #     apply functions over field
        @delegate_onefield_twovars,            #          (return type from func)
        @delegate_onefield_threevars,          #          (return type from func)
        @delegate_onefield_astype,             #     and reobtain the same type
        @delegate_onefield_twovars_astype,     #          (return type from arg)
        @delegate_onefield_threevars_astype,   #          (return type from arg)
                                               #
        @delegate_twofields,                   #     apply functions over fields
        @delegate_twofields_twovars,           #          (return type from func)
        @delegate_twofields_astype,            #     and reobtain the same type
        @delegate_twofields_twovars_astype,    #          (return type from args)
                                               #
        @delegate_threefields,                 #     apply functions over fields
        @delegate_threefields_twovars,         #          (return type from func)
        @delegate_threefields_astype,          #     and reobtain the same type
        @delegate_threefields_twovars_astype   #          (return type from args)
"""
module TypedDelegation

export  @delegate_type,                        #
        @delegate_type_astype,                 #
                                               #
        @delegate_onefield,                    #     apply functions over field
        @delegate_onefield_twovars,            #          (return type from func)
        @delegate_onefield_threevars,          #          (return type from func)
        @delegate_onefield_astype,             #     and reobtain the same type
        @delegate_onefield_twovars_astype,     #          (return type from arg)
        @delegate_onefield_threevars_astype,   #          (return type from arg)
                                               #
        @delegate_twofields,                   #     apply functions over fields
        @delegate_twofields_twovars,           #          (return type from func)
        @delegate_twofields_astype,            #     and reobtain the same type
        @delegate_twofields_twovars_astype,    #          (return type from args)
                                               #
        @delegate_threefields,                 #     apply functions over fields
        @delegate_threefields_twovars,         #          (return type from func)
        @delegate_threefields_astype,          #     and reobtain the same type
        @delegate_threefields_twovars_astype   #          (return type from args)


#=
      internal macros, compositable
=#

"""
    @fieldtypes( aType )

works like aType.types
"""
macro fieldtypes( aType )
    esc( :( getfield( $aType, :types ) ) )
end

"""
    @fieldsyms( aType )

works like fieldnames(aType)
"""
macro fieldsyms( aType )
    esc( :( fieldnames( $aType ) ) )
end

"""
    @fieldsyms( aType, nfields )

yields the symbols for the first nfields declared in Type (in order)
"""
macro fieldsyms( aType, nfields )
    return quote
        local allsyms = @fieldsyms( $aType )
        local syms = allvals[1:$nfields]
        syms
    end
end


"""
    @getfield( varOfType, symfieldOfType )

works like getfield(varOfType, symfieldOfType)
"""
macro getfield( varOfType, symfieldOfType)
    esc( :( getfield( ($varOfType), ($symfieldOfType) )) )
end

"""
    @getfields( varOfType )

yields a tuple of field values for varOfType (in order)
"""
macro getfields( varOfType )
    return quote
        local syms = @fieldsyms( typeof( $varOfType ) )
        local vals = Vector( 0 )
        for item in syms
            push!( vals, @getfield( $varOfType, item ) )
        end
        (vals...,)
    end
end


"""
    @fieldvalues( varOfType )

yields the values of the fields in varOfType (in order)
"""
macro fieldvalues( varOfType )
    esc( :( @getfields( $varOfType ) ) )
end

"""
    @fieldvalues( varOfType, nfields )

yields the values of the first nfields declared in Type (in order)
"""
macro fieldvalues( varOfType, nfields )
    return quote
        local allvals = @fieldvalues( $varOfType )
        local vals = allvals[1:$nfields]
        vals
    end
end


#=
       delegation using the type itself
=#

macro delegate_type(sourceType, usedType, targetedFuncs)
    typesname  = esc( :($sourceType) )
    targetname = esc( :($usedType) )
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs)
    for i in 1:nfuncs
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(::Type{$typesname}) =
                   ($funcname)($targetname)
               end
    end
    return Expr(:block, fdefs...)
end

macro delegate_type_astype(sourceType, usedType, targetedFuncs)
    typesname  = esc( :($sourceType) )
    targetname = esc( :($usedType) )
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs)
    for i in 1:nfuncs
    funcname = esc(funcnames[i])
    fdefs[i] = quote
                 ($funcname)(::Type{$typesname}) =
                   ($typesname)( ($funcname)($targetname) )
               end
    end
    return Expr(:block, fdefs...)
end


#=
         delegation using one field of a type
         when the result type differs from the type of the params
=#


"""
    @delegate_onefield(sourceType, sourcefield, targetedFuncs)

This returns a value of same types as the `targetedFuncs` result types.

    import Base: string, show

    struct MyInt16
      value::Int16
    end
    
    @delegate_onefield( MyInt16, value, [string, show]);
    
    three = MyInt16(3);
    seven = MyInt16(7);

    string(three) == "3"           # true
    show(seven)                    # 7
"""
macro delegate_onefield(sourceType, sourcefield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    fieldname  = esc(Expr(:quote, sourcefield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*1)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname)) =
                       ($funcname)(getfield(a,($fieldname)))
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), args...) =
                       ($funcname)(getfield(a,($fieldname)), args...)
                   end
    end
    return Expr(:block, fdefs...)
end


"""
    @delegate_onefield_twovars(sourceType, sourcefield, targetedFuncs)

This returns a value of same types as the `targetedOps` result types.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)

    import Base: (<), (<=)

    struct MyInt16
      value::Int16
    end;

    @delegate_onefield_twovars( MyInt16, value, [ (<), (<=) ] );

    three = MyInt16(3);
    seven = MyInt16(7);

    three <  seven                 # true
    !(seven <= three)              # true
"""
macro delegate_onefield_twovars(sourceType, sourcefield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    fieldname  = esc(Expr(:quote, sourcefield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname), b::($typesname)) =
                       ($funcname)(getfield(a,($fieldname)),
                                   getfield(b,($fieldname)))
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), b::($typesname), args...) =
                       ($funcname)(getfield(a,($fieldname)),
                                   getfield(b,($fieldname)), args...)
                   end
    end
    return Expr(:block, fdefs...)
end

"""
    @delegate_onefield_threevars(sourceType, sourcefield, targetedFuncs)
"""
macro delegate_onefield_threevars(sourceType, sourcefield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    fieldname  = esc(Expr(:quote, sourcefield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname), b::($typesname), c::($typesname)) =
                       ($funcname)(getfield(a,($fieldname)),
                                   getfield(b,($fieldname)),
                                   getfield(c,($fieldname)))
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), b::($typesname), c::($typesname), args...) =
                       ($funcname)(getfield(a,($fieldname)),
                                   getfield(b,($fieldname)),
                                   getfield(c,($fieldname)), args...)
                   end
    end
    return Expr(:block, fdefs...)
end

#=
         delegation using one field of a type
         when the result has the same type as the params
=#


"""
    @delegate_onefield_astype(sourceType, sourcefield, targetedOps)

This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: abs, (-)

    struct MyInt16
      value::Int16
    end

    @delegate_onefield_astype( MyInt16, value, [abs, (-)]);

    three = MyInt16(3);
    seven = MyInt16(7);

    abs(three) == three            # true
    -(seven) === MyInt16(-7)       # true
"""
macro delegate_onefield_astype(sourceType, sourcefield, targetedOps)
    typesname  = esc( :($sourceType) )
    fieldname  = esc(Expr(:quote, sourcefield))
    funcnames  = targetedOps.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname)) =
                       ($typesname)( ($funcname)(getfield(a,($fieldname))) )
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), args...) =
                       ($typesname)( ($funcname)(getfield(a,($fieldname)), args...) )
                   end
    end
    return Expr(:block, fdefs...)
end


"""
    @delegate_onefield_twovars_astype(sourceType, sourcefield, targetedOps)

This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: (+), (-), (*)

    struct MyInt16
      value::Int16
    end

    @delegate_onefield_twovars_astype( MyInt16, value, [ (+), (*) ] );

    three = MyInt16(3);
    seven = MyInt16(7);    

    import Base: hypot    

    struct RightTriangle
      legA::Float64
      legB::Float64
    end;

    @delegate_twofields( RightTriangle, legA, legB, [ hypot, ] );

    myRightTriangle  = RightTriangle( 3.0, 4.0 );
    hypot(myRightTriangle)   #  5.0

    three + seven == MyInt16(3+7)  # true
    three * seven == MyInt16(3*7)  # true
"""
macro delegate_onefield_twovars_astype(sourceType, sourcefield, targetedOps)
    typesname  = esc( :($sourceType) )
    fieldname  = esc(Expr(:quote, sourcefield))
    funcnames  = targetedOps.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname), b::($typesname)) =
                       ($typesname)( ($funcname)(getfield(a,($fieldname)),
                                                 getfield(b,($fieldname))) )
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), b::($typesname), args...) =
                       ($typesname)( ($funcname)(getfield(a,($fieldname)),
                                                 getfield(b,($fieldname)), args...) )
                   end
    end
    return Expr(:block, fdefs...)
end

"""
    @delegate_onefield_threevars_astype(sourceType, sourcefield, targetedFuncs)
"""
macro delegate_onefield_threevars_astype(sourceType, sourcefield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    fieldname  = esc(Expr(:quote, sourcefield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname), b::($typesname), c::($typesname)) =
                       ($typesname)( ($funcname)(getfield(a,($fieldname)),
                                                 getfield(b,($fieldname)),
                                                 getfield(c,($fieldname))) )
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), b::($typesname), c::($typesname), args...) =
                       ($typesname)( ($funcname)(getfield(a,($fieldname)),
                                                 getfield(b,($fieldname)),
                                                 getfield(c,($fieldname)), args...) )
                   end
    end
    return Expr(:block, fdefs...)
end


#=
        delegation using two fields of a type
        when the result type differs from the type of the params
=#

"""    import Base: hypot

    struct RightTriangle
      legA::Float64
      legB::Float64
    end;

    @delegate_twofields( RightTriangle, legA, legB, [ hypot, ] );

    myRightTriangle  = RightTriangle( 3.0, 4.0 );
    hypot(myRightTriangle)   #  5.0
    @delegate_twofields(sourceType, firstfield, secondfield, targetedFuncs)

This returns a value of same types as the `targetedFuncs` result types.

    import Base: hypot

    struct RightTriangle
      legA::Float64
      legB::Float64
    end;

    @delegate_twofields( RightTriangle, legA, legB, [ hypot, ] );

    myRightTriangle  = RightTriangle( 3.0, 4.0 );
    hypot(myRightTriangle)   #  5.0
"""
macro delegate_twofields(sourceType, firstfield, secondfield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    field1name = esc(Expr(:quote, firstfield))
    field2name = esc(Expr(:quote, secondfield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname)) =
                       ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)))
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), args...) =
                       ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), args...)
                   end
    end
    return Expr(:block, fdefs...)
end


#=
        delegation using two fields of a type
        when the result has the same type as the params
=#

"""
    @delegate_twofields_astype(sourceType, firstfield, secondfield, targetedOps)

This returns a value of the same type as the `sourceType` by rewrapping the result.

    function renormalize(a::Float64, b::Float64)
      hi = a + b
      t = hi - a
      lo = (a - (hi - t)) + (b - t)
      return hi, lo
    end

    struct HiLo
      hi::Float64
      lo::Float64
    end;

    @delegate_twofields_astype( HiLo, hi, lo, [ renormalize, ] );

    myHiLo = renormalize( HiLo(12.555555555, 8000.333333333) );
    show(myHiLo)     # HiLo(8012.888888888,4.440892098500626e-14)
"""
macro delegate_twofields_astype(sourceType, firstfield, secondfield, targetedOps)
    typesname  = esc( :($sourceType) )
    field1name = esc(Expr(:quote, firstfield))
    field2name = esc(Expr(:quote, secondfield))
    funcnames  = targetedOps.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname)) =
                        ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)))... )
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), args...) =
                        ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), args...)... )
                   end
    end
    return Expr(:block, fdefs...)
end


"""
    @delegate_twofields_twovars(sourceType, firstfield, secondfield, targetedFuncs)

This returns a value of same types as the `targetedFuncs` result types.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)       
  that evalutes two fields of `TheType` from arg1 and also from arg2.    
      
    result = targetedFunc( arg1.firstfield, arg1.secondfield,
                           arg2.firstfield, arg2.secondfield )

    import Base: mean

    type MyInterval
      lo::Float64
      hi::Float64

      function MyInterval(lo::Float64, hi::Float64)
         mn, mx = ifelse( hi<lo, (hi, lo), (lo, hi) )
         new( mn, mx )
      end
    end

    MyInterval(lo::T, hi::T) where T<:Real =
        MyInterval( Float64(lo), Float64(hi) )

    @delegate_twofields_twovars( MyInterval, lo, hi, [ mean, ])

    function mean( x::MyInterval )
        return x.lo * 0.5 + x.hi * 0.5
    end

    function mean( a::MyInterval, b::MyInterval )
        return mean( a ) * 0.5 + mean( b ) * 0.5
    end

    one_three = MyInterval(1.0, 3.0);
    two_four  = MyInterval(2.0, 4.0);

    mean( one_three, two_four ) == 2.5 # true
"""
macro delegate_twofields_twovars(sourceType, firstfield, secondfield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    field1name = esc(Expr(:quote, firstfield))
    field2name = esc(Expr(:quote, secondfield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname), b::($typesname)) =
                         ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)),
                                     getfield(b, ($field1name)), getfield(b, ($field2name)))
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), b::($typesname), args...) =
                         ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)),
                                     getfield(b, ($field1name)), getfield(b, ($field2name)),
                                     args...)
                   end
    end
    return Expr(:block, fdefs...)
end


"""
    @delegate_twofields_twovars_astype(sourceType, firstfield, secondfield, targetedOps)

This returns a value of the same type as the `sourceType` by rewrapping the result.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)    
  that evalutes two fields of `TheType` from arg1 and also from arg2    
  and applies itself over them, obtaining field_values for constructive    
  generation of the result; a new realization of TheType( field_values... ).

    TheType( targetedFunc( arg1.firstfield, arg1.secondfield,
                           arg2.firstfield, arg2.secondfield )... )


    import Base: union, intersect

    type MyInterval
      lo::Float64
      hi::Float64

      function MyInterval(lo::Float64, hi::Float64)
         mn, mx = ifelse( hi<lo, (hi, lo), (lo, hi) )
         new( mn, mx )
      end
    end;

    MyInterval(lo::T, hi::T) where T<:Real =
        MyInterval( Float64(lo), Float64(hi) )

    @delegate_twofields_twovars_astype( MyInterval, lo, hi, [ union, ])

    function union( a::T, b::T ) where {T<:MyInterval}
        lo = min( a.lo, b.lo )
        hi = max( a.hi, b.hi )
        return T( lo, hi )
    end

    one_three = MyInterval(1.0, 3.0);
    two_four  = MyInterval(2.0, 4.0);

    union( one_three, two_four ) == MyInterval(1.0, 4.0) # true
"""
macro delegate_twofields_twovars_astype(sourceType, firstfield, secondfield, targetedOps)
    typesname  = esc( :($sourceType) )
    field1name = esc(Expr(:quote, firstfield))
    field2name = esc(Expr(:quote, secondfield))
    funcnames  = targetedOps.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname), b::($typesname)) =
                        ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)),
                                                  getfield(b, ($field1name)), getfield(b, ($field2name)))... )
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), b::($typesname), args...) =
                        ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)),
                                                  getfield(b, ($field1name)), getfield(b, ($field2name)),
                                                  args...)... )
                   end
    end
    return Expr(:block, fdefs...)
end


#=
        delegation using three fields of a type
        when the result type differs from the type of the params
=#

"""
    @delegate_threefields(sourceType, firstfield, secondfield, targetedFuncs)

This returns a value of same types as the `targetedFuncs` result types.

    import Base: norm

    norm{R<:Real}(xs::Vararg{R,3}) = norm([xs...])

    struct XYZ
      x::Float64
      y::Float64
      z::Float64
    end;

    @delegate_threefields( XYZ, x, y, z, [ norm, ] );

    pointA  = XYZ( 3.0, 4.0, 5.0 );

    norm(pointA)   #  7.0710678+
"""
macro delegate_threefields(sourceType, firstfield, secondfield, thirdfield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    field1name = esc(Expr(:quote, firstfield))
    field2name = esc(Expr(:quote, secondfield))
    field3name = esc(Expr(:quote, thirdfield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname)) =
                       ($funcname)(getfield(a, ($field1name)),
                                   getfield(a, ($field2name)),
                                   getfield(a, ($field3name)))
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), args...) =
                       ($funcname)(getfield(a, ($field1name)),
                                   getfield(a, ($field2name)),
                                   getfield(a, ($field3name)), args...)
                   end
    end
    return Expr(:block, fdefs...)
end


#=
        delegation using three fields of a type
        when the result has the same type as the params
=#

"""
    @delegate_threefields_astype(sourceType, firstfield, secondfield, targetedOps)

This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: normalize

    normalize{R<:Real}(xs::Vararg{R,3}) = normalize([xs...])

    struct XYZ
      x::Float64
      y::Float64
      z::Float64
    end;

    @delegate_threefields_astype( XYZ, x, y, z, [ normalize, ] );

    pointA  = XYZ( 3.0, 4.0, 5.0 );

    normalize(pointA)   #  XYZ( 0.424264+, 0.565685+, 0.707107- )
"""
macro delegate_threefields_astype(sourceType, firstfield, secondfield, thirdfield, targetedOps)
    typesname  = esc( :($sourceType) )
    field1name = esc(Expr(:quote, firstfield))
    field2name = esc(Expr(:quote, secondfield))
    field3name = esc(Expr(:quote, thirdfield))
    funcnames  = targetedOps.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname)) =
                        ($typesname)( ($funcname)(getfield(a, ($field1name)),
                                                  getfield(a, ($field2name)),
                                                  getfield(a, ($field3name)))... )
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), args...) =
                        ($typesname)( ($funcname)(getfield(a, ($field1name)),
                                                  getfield(a, ($field2name)),
                                                  getfield(a, ($field3name)), args...)... )
                   end
    end
    return Expr(:block, fdefs...)
end


"""
    @delegate_threefields_twovars(sourceType, firstfield, secondfield, thirdfield, targetedFuncs)

This returns a value of same types as the `targetedFuncs` result types.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)    
  that evalutes three fields of `TheType` from arg1 and also from arg2.    
      
    result = targetedFunc( arg1.firstfield, arg1.secondfield, arg1.thirdfield,    
                           arg2.firstfield, arg2.secondfield, arg2.thirdfield )
 
    import Base: norm, normalize, cross, sin
    
    normalize(xs::Vararg{R,3}) where R<:Real  = normalize([xs...])
    cross(xs::Vararg{R,6}) where R<:Real = cross([xs[1:3]...], [xs[4:6]...])
    
    struct XYZ
      x::Float64
      y::Float64
      z::Float64
    end;
    
    @delegate_threefields_astype( XYZ, x, y, z, [ normalize, ] );
    @delegate_threefields_twovars( XYZ, x, y, z, [ cross, ] );
    
    function sin( pointA::XYZ, pointB::XYZ )
        norm( cross( normalize(pointA), normalize(pointB) ) )
    end

    pointA  = XYZ( 3.0, 4.0, 5.0 );
    pointB  = XYZ( 5.0, 4.0, 3.0 );

    sin(pointA, pointB) #  0.391918+
"""
macro delegate_threefields_twovars(sourceType, firstfield, secondfield, thirdfield, targetedFuncs)
    typesname  = esc( :($sourceType) )
    field1name = esc(Expr(:quote, firstfield))
    field2name = esc(Expr(:quote, secondfield))
    field3name = esc(Expr(:quote, thirdfield))
    funcnames  = targetedFuncs.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname), b::($typesname)) =
                         ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), getfield(a, ($field3name)),
                                     getfield(b, ($field1name)), getfield(b, ($field2name)), getfield(b, ($field3name)))
                   end
        end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), b::($typesname), args...) =
                         ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), getfield(a, ($field3name)),
                                     getfield(b, ($field1name)), getfield(b, ($field2name)), getfield(b, ($field3name)),
                                     args...)
                   end
        end
    return Expr(:block, fdefs...)
end


"""
    @delegate_threefields_twovars_astype(sourceType, firstfield, secondfield, thirdfield, targetedOps)

This returns a value of the same type as the `sourceType` by rewrapping the result.

A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)    
  that evalutes three fields of `TheType` from arg1 and also from arg2    
  and applies itself over them, obtaining field_values for constructive    
  generation of the result; a new realization of TheType( field_values... ).    

  TheType( targetedFunc( arg1.firstfield, arg1.secondfield, arg1.thirdfield,    
                         arg2.firstfield, arg2.secondfield, arg2.thirdfield )... )    

    import Base: cross

    cross(xs::Vararg{R,6}) where R<:Real = cross([xs[1:3]...], [xs[4:6]...])

    struct XYZ
      x::Float64
      y::Float64
      z::Float64
    end

    @delegate_threefields_twovars_astype( XYZ, x, y, z, [ cross, ] );

    pointA  = XYZ( 3.0, 4.0, 5.0 );
    pointB  = XYZ( 5.0, 4.0, 3.0 );

    cross(pointA, pointB) #  XYZ(-8.0, 16.0, -8.0)
"""
macro delegate_threefields_twovars_astype(sourceType, firstfield, secondfield,  thirdfield, targetedOps)
    typesname  = esc( :($sourceType) )
    field1name = esc(Expr(:quote, firstfield))
    field2name = esc(Expr(:quote, secondfield))
    field3name = esc(Expr(:quote, thirdfield))
    funcnames  = targetedOps.args
    nfuncs = length(funcnames)
    fdefs = Array{Expr}(undef, nfuncs*2)
    for i in 1:nfuncs
        funcname = esc(funcnames[i])
        fdefs[i] = quote
                     ($funcname)(a::($typesname), b::($typesname)) =
                         ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), getfield(a, ($field3name)),
                                                   getfield(b, ($field1name)), getfield(b, ($field2name)), getfield(b, ($field3name)))... )
                   end
        fdefs[i+nfuncs] = quote
                     ($funcname)(a::($typesname), b::($typesname), args...) =
                         ($typesname)( ($funcname)(getfield(a, ($field1name)), getfield(a, ($field2name)), getfield(a, ($field3name)),
                                                   getfield(b, ($field1name)), getfield(b, ($field2name)), getfield(b, ($field3name)),
                                                   args...)... )
                   end
    end
    return Expr(:block, fdefs...)
end



#=
    earlier implementations
    description and logic from John Myles White
        <https://gist.github.com/johnmyleswhite/5225361>
    additional macro work from DataStructures.jl
        <https://github.com/JuliaLang/DataStructures.jl/blob/master/src/delegate.jl?
    and delegation with n-ary ops from Toivo Henningsson
        <https://groups.google.com/forum/#!msg/julia-dev/MV7lYRgAcB0/-tS50TreaPoJ?
=#

end # moduleTypedDelegation
