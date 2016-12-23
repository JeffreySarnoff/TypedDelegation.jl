## TypedDelegation.jl
=====

#### Use a Type's fields as operands for the type's operations. Apply functions onto fields' values.  Easily.<

Copyright © 2016 by Jeffrey Sarnoff.  Released under the MIT License.

=====

### Offers

- Delegation macros, designed for easy use.   
- Apply functions over a Type's field's values.  
- Use fields as operands with type consistent operators.


### Exports

This package offers macros that delegate functions over one or more fields of a type;      
and macros that delegate operations through fields to return a value of the same type.

```julia
        #     apply functions through a given Type T, using one field as a parameter
        #
        #           evaluates as the type that the function returns
        @delegate_oneField,                       #  fn(x::T)
        @delegate_oneField_fromTwoVars,           #  fn(x::T, y::T)
        #
        #           evaluates as the type that is used in delegation
        @delegate_oneField_asType,                #  op(x::T)::T
        @delegate_oneField_fromTwoVars_asType,    #  op(x::T, y::T)::T
                                                  #
        #     apply functions through a given Type, using two fields as parameters
        #
        #           evaluates as the type that the function returns
        @delegate_twoFields,                      #  fn(x::T)
        @delegate_twoFields_fromTwoVars,          #  fn(x::T, y::T)
        #
        #           evaluates as the type that is used in delegation
        @delegate_twoFields_asType,               #  op(x::T)::T
        @delegate_twoFields_fromTwoVars_asType    #  op(x::T, y::T)::T

                                                  #
        #     apply functions through a given Type, using three fields as parameters
        #
        #           evaluates as the type that the function returns
        @delegate_threeFields,                    #  fn(x::T)
        @delegate_threeFields_fromTwoVars,        #  fn(x::T, y::T)
        #
        #           evaluates as the type that is used in delegation
        @delegate_threeFields_asType,             #  op(x::T)::T
        @delegate_threeFields_fromTwoVars_asType  #  op(x::T, y::T)::T
```


====================
   
### Install and Use
```julia
Pkg.add("TypedDelegation")
using TypedDelegation   
```

### Examples of Use

#### Delegation with one field


```julia
# @delegate_oneField(sourceType, sourceField, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.

    import Base: string, show

    immutable MyInt16
      value::Int16
    end

    @delegate_oneField( MyInt16, value, [string, show]);

    three = MyInt16(3);
    seven = MyInt16(7);

    string(three) == "3"           # true
    show(seven)                    # 7
```
   
   
   
```julia
# @delegate_oneField_fromTwoVars(sourceType, sourceField, targetedOps)
# This returns a value of same types as the `targetedOps` result types.
#
# A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)

    import Base: (<), (<=)

    immutable MyInt16  
      value::Int16  
    end;

    @delegate_oneField_fromTwoVars( MyInt16, value, [ (<), (<=) ] );

    three = MyInt16(3);
    seven = MyInt16(7);

    three <  seven                 # true
    seven <= three                 # false
```
   
   
   
```julia
# @delegate_oneField_asType(sourceType, sourceField, targetedFuncs)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: abs, (-)

    immutable MyInt16
      value::Int16
    end

    @delegate_oneField_asType( MyInt16, value, [abs, (-)]);

    three = MyInt16(3);
    seven = MyInt16(7);

    abs(three) == three            # true
    -(seven) === MyInt16(-7)       # true
```
   
   
   
```julia
# @delegate_oneField_fromTwoVars_asType(sourceType, sourceField, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: (+), (-), (*)

    immutable MyInt16
      value::Int16
    end

    @delegate_oneField_fromTwoVars_asType( MyInt16, value, [ (+), (*) ] );

    three = MyInt16(3);
    seven = MyInt16(7);

    three + seven == MyInt16(3+7)  # true
    three * seven == MyInt16(3*7)  # true```
```
   
#### Delegation with two fields
   
   
```
# @delegate_twoFields(sourceType, firstField, secondField, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.

    import Base: hypot
    
    immutable RightTriangle
      legA::Float64;
      legB::Float64;  
    end;

    @delegate_twoFields( RightTriangle, legA, legB, [ hypot, ] );
  
    myRightTriangle  = RightTriangle( 3.0, 4.0 );
    hypot(myRightTriangle)   #  5.0
```
   
   
   
```
# @@delegate_twoFields_asType(sourceType, firstField, secondField, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

    function renormalize(a::Float64, b::Float64)
      hi = a + b
      t = hi - a
      lo = (a - (hi - t)) + (b - t)
      return hi, lo
    end

    immutable HiLo  
      hi::Float64;
      lo::Float64;   
    end;
    
    @delegate_twoFields_asType( HiLo, hi, lo, [ renormalize, ] );

    myHiLo = renormalize( HiLo(12.555555555, 8000.333333333) ); 
    showall(myHiLo)     # HiLo(8012.888888888,4.440892098500626e-14)
```


```julia
# @delegate_twoFields_fromTwoVars(sourceType, firstField, secondField, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.

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
```

```julia
# @delegate_twoFields_fromTwoVars_asType(sourceType, firstField, secondField, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

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
```   

#### Delegation with three fields

   
```
# @delegate_threeFields(sourceType, firstField, secondField, thirdField, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.


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
```
   
   
   
```
# @@delegate_threeFields_asType(sourceType, firstField, secondField, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

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
```


```julia
# @delegate_threeFields_fromTwoVars(sourceType, firstField, secondField, thirdField, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.

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
```

```julia
# @delegate_threeFields_fromTwoVars_asType(sourceType, firstField, secondField, thirdField, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

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
```   

------

### Notes

[TypedDelegation.jl](https://github.com/JuliaArbTypes/TypedDelegation.jl) v0.1.2 for Julia v0.5, 0.6


### References

This derives directly from work by John Myles White and Toivo Henningsson.

- description and logic from John Myles White  
--   (https://gist.github.com/johnmyleswhite/5225361)
  
- delegation with nary ops fromToivo Henningsson  
--   (https://groups.google.com/forum/#!msg/julia-dev/MV7lYRgAcB0/-tS50TreaPoJ)
 
- additional macro text from  
--   (https://github.com/JuliaLang/DataStructures.jl/blob/master/src/delegate.jl)

