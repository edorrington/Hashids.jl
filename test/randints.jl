using Hashids

h = Hashid("salt")

# Testing against single random positive ints
for i in 1:1000
    test_id = abs(rand(Int))
    hashed_id = encode(h,test_id)
    unhashed_id = first(decode(h, hashed_id))
    @assert unhashed_id == test_id
end


# Test against multi-arity version
for i in 1:100
    test_ids = abs.(rand(Int,10))
    hashed_ids = encode(h,test_ids...)
    unhashed_ids = decode(h, hashed_ids) 
    @assert unhashed_ids == test_ids
end

