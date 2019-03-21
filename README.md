## TypedDelegation.jl

### Use a Type's fields as operands for the type's operations. Easily apply functions onto fields.

##### Copyright © 2016-2017 by Jeffrey Sarnoff.  Released under the MIT License.  

------

|    |     |
|:------:|:-----------------------------------------|
|  _travis build status_ |  [![Build Status](https://travis-ci.org/JuliaArbTypes/TypedDelegation.jl.svg?branch=master)](https://travis-ci.org/JuliaArbTypes/TypedDelegation.jl) | 

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
        @delegate_onefield,                   #  fn(x::T)
        @delegate_onefield_twovars,           #  fn(x::T, y::T)
        @delegate_onefield_threevars,         #  fn(x::T, y::T, x::T)
        #
        #           evaluates as the type that is used in delegation
        @delegate_onefield_astype,            #  op(x::T)::T
        @delegate_onefield_twovars_astype,    #  op(x::T, y::T)::T
        @delegate_onefield_threevars_astype,  #  op(x::T, y::T, x::T)::T
        #
        #     apply functions through a given Type, using two fields as parameters
        #
        #           evaluates as the type that the function returns
        @delegate_twofields,                  #  fn(x::T)
        @delegate_twofields_twovars,          #  fn(x::T, y::T)
        #
        #           evaluates as the type that is used in delegation
        @delegate_twofields_astype,           #  op(x::T)::T
        @delegate_twofields_twovars_astype    #  op(x::T, y::T)::T
        #
        #     apply functions through a given Type, using three fields as parameters
        #
        #           evaluates as the type that the function returns
        @delegate_threefields,                #  fn(x::T)
        @delegate_threefields_twovars,        #  fn(x::T, y::T)
        #
        #           evaluates as the type that is used in delegation
        @delegate_threefields_astype,         #  op(x::T)::T
        @delegate_threefields_twovars_astype  #  op(x::T, y::T)::T
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
# @delegate_onefield(sourceType, sourcefield, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.

    import Base: string, show

    struct MyInt16
      value::Int16
    end

    @delegate_onefield( MyInt16, value, [string, show]);

    three = MyInt16(3);
    seven = MyInt16(7);

    string(three) == "3"           # true
    show(seven)                    # 7
```
   
   
   
```julia
# @delegate_onefield_twovars(sourceType, sourcefield, targetedOps)
# This returns a value of same types as the `targetedOps` result types.
#
# A macro for field delegation over a function{T<:TheType}(arg1::T, arg2::T)

    import Base: (<), (<=)

    struct MyInt16  
      value::Int16  
    end;

    @delegate_onefield_twovars( MyInt16, value, [ (<), (<=) ] );

    three = MyInt16(3);
    seven = MyInt16(7);

    three <  seven                 # true
    seven <= three                 # false
```
   
   
   
```julia
# @delegate_onefield_astype(sourceType, sourcefield, targetedFuncs)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: abs, (-)

    struct MyInt16
      value::Int16
    end

    @delegate_onefield_astype( MyInt16, value, [abs, (-)]);

    three = MyInt16(3);
    seven = MyInt16(7);

    abs(three) == three            # true
    -(seven) === MyInt16(-7)       # true
```
   
   
   
```julia
# @delegate_onefield_twovars_astype(sourceType, sourcefield, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: (+), (-), (*)

    struct MyInt16
      value::Int16
    end

    @delegate_onefield_twovars_astype( MyInt16, value, [ (+), (*) ] );

    three = MyInt16(3);
    seven = MyInt16(7);

    three + seven == MyInt16(3+7)  # true
    three * seven == MyInt16(3*7)  # true```
```
   
#### Delegation with two fields
   
   
```
# @delegate_twofields(sourceType, firstfield, secondfield, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.

    import Base: hypot
    
    immutable RightTriangle
      legA::Float64;
      legB::Float64;  
    end;

    @delegate_twofields( RightTriangle, legA, legB, [ hypot, ] );
  
    myRightTriangle  = RightTriangle( 3.0, 4.0 );
    hypot(myRightTriangle)   #  5.0
```
   
   
   
```
# @@delegate_twofields_astype(sourceType, firstfield, secondfield, targetedOps)
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
    
    @delegate_twofields_astype( HiLo, hi, lo, [ renormalize, ] );

    myHiLo = renormalize( HiLo(12.555555555, 8000.333333333) ); 
    showall(myHiLo)     # HiLo(8012.888888888,4.440892098500626e-14)
```


```julia
# @delegate_twofields_twovars(sourceType, firstfield, secondfield, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.

    import Base: mean

    mutable struct MyInterval
      lo::Float64
      hi::Float64
    
      function MyInterval(lo::Float64, hi::Float64)
         mn, mx = ifelse( hi<lo, (hi, lo), (lo, hi) )
         new( mn, mx )
      end   
    end;

    MyInterval(lo::T, hi::T) where {T<:AbstractFloat} =
        MyInterval( Float64(lo), Float64(hi) )

    @delegate_twofields_twovars( MyInterval, lo, hi, [ mean, ])

    function mean( x::MyInterval )
        return x.lo * 0.5 + x.hi * 0.5
    end
    function mean( a::T, b::T ) where T<:MyInterval
        return mean( a ) * 0.5 + mean( b ) * 0.5
    end

    one_three = MyInterval(1, 3);
    two_four  = MyInterval(2, 4);

    mean( one_three, two_four ) == 2.5 # true
```

```julia
# @delegate_twofields_twovars_astype(sourceType, firstfield, secondfield, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: union, intersect

    mutable struct MyInterval
      lo::Float64
      hi::Float64
    
      function MyInterval(lo::Float64, hi::Float64)
         mn, mx = ifelse( hi<lo, (hi, lo), (lo, hi) )
         new( mn, mx )
      end   
    end;

    MyInterval(lo::T, hi::T) where {T<:AbstractFloat} =
        MyInterval( Float64(lo), Float64(hi) )

    @delegate_twofields_twovars_astype( MyInterval, lo, hi, [ union, ])

    function union( a::T, b::T ) where T<:MyInterval
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
# @delegate_threefields(sourceType, firstfield, secondfield, thirdfield, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.


    import Base: norm 
    
    norm{R<:Real}(xs::Vararg{R,3}) = norm([xs...])
    
    immutable XYZ
      x::Float64
      y::Float64
      z::Float64
    end;
    
    @delegate_threefields( XYZ, x, y, z, [ norm, ] );
  
    pointA  = XYZ( 3.0, 4.0, 5.0 );
    
    norm(pointA)   #  7.0710678+
```
   
   
   
```
# @@delegate_threefields_astype(sourceType, firstfield, secondfield, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: normalize
    
    normalize{R<:Real}(xs::Vararg{R,3}) = normalize([xs...])
    
    immutable XYZ
      x::Float64
      y::Float64
      z::Float64
    end;
    
    @delegate_threefields_astype( XYZ, x, y, z, [ normalize, ] );
    
    pointA  = XYZ( 3.0, 4.0, 5.0 );
    
    normalize(pointA)   #  XYZ( 0.424264+, 0.565685+, 0.707107- )
```


```julia
# @delegate_threefields_twovars(sourceType, firstfield, secondfield, thirdfield, targetedFuncs)
# This returns a value of same types as the `targetedFuncs` result types.

    import Base: norm, normalize, cross, sin
    
    normalize(xs::Vararg{R,3}) where {R<:Real} = normalize([xs...])
    cross(xs::Vararg{R,6}) where {R<:Real} = cross([xs[1:3]...], [xs[4:6]...])
    
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
```

```julia
# @delegate_threefields_twovars_astype(sourceType, firstfield, secondfield, thirdfield, targetedOps)
# This returns a value of the same type as the `sourceType` by rewrapping the result.

    import Base: cross
    
    cross(xs::Vararg{R,6}) where {R<:Real} = cross([xs[1:3]...], [xs[4:6]...])
    
    struct XYZ
      x::Float64
      y::Float64
      z::Float64
    end;
    
    @delegate_threefields_twovars_astype( XYZ, x, y, z, [ cross, ] );
    
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
