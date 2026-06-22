require_relative 'helper'

T.assert_integer         { 1 + 1 }
T.assert_rational        { 1 + 1r }
T.assert_float           { 1 + 1.0 }
T.assert_complex         { 1 + 1i }
T.assert_class(MyReturn) { 1 + MyCoerce.new }

T.assert_rational        { 1r + 1 }
T.assert_rational        { 1r + 1r }
T.assert_float           { 1r + 1.0 }
T.assert_complex         { 1r + 1i }
T.assert_class(MyReturn) { 1r + MyCoerce.new }

T.assert_float           { 1.0 + 1 }
T.assert_float           { 1.0 + 1r }
T.assert_float           { 1.0 + 1.0 }
T.assert_complex         { 1.0 + 1i }
T.assert_class(MyReturn) { 1.0 + MyCoerce.new }

T.assert_complex         { 1i + 1 }
T.assert_complex         { 1i + 1r }
T.assert_complex         { 1i + 1.0 }
T.assert_complex         { 1i + 1i }
# T.assert_class(MyReturn) { 1i + MyCoerce.new }
