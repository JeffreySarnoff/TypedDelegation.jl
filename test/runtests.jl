using TypedDelegation
using Base.Test

import Base: string, abs, 
             (+), (-), (*), div, fld, cld,
             (==), (!=), (<), (<=), (>=), (>)

immutable MyInt16
    value::Int16
end

@delegate_onefield( MyInt16, value, [ string ]);
@delegate_onefield_twovars( MyInt16, value, [ (==), (!=), (<), (<=), (>=), (>) ] );
@delegate_onefield_astype( MyInt16, value, [ abs, (-) ]); # unary minus
@delegate_onefield_twovars_astype( MyInt16, value, [ (+), (-), (*), div, fld, cld ] );

# values to be used in testing
three = MyInt16(3);
seven = MyInt16(7);

# testing four of the eight exported macros, one of each kind

  @test  string(three) == "3"
  @test  three < seven
  @test -three < three
  @test  seven == div( seven*three, three )

# end tests
