#
# Tests
#

using Hashids

tests = ["randints.jl"]
				
println("Running test:")

for tst in tests
	println(" * $(tst)")
	include(tst)
end
