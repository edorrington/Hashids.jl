# Hashids.jl

### Install

`julia> Pkg.clone("git://github.com/edorrington/Hashids.jl.git")`

### Usage

```
julia> using Hashids

julia> h = Hashid("salt")  # can also include minimum hash length and alternate alphabet
julia> enc = encode(h,313)    # = "..."
julia> dec = decode(h,enc)    # = [313]

### License

MIT
