const seps = "cfhistuCFHISTU"
const sep_div = 3.5
const guard_div = 12
const minalphalen = 16

function consistent_shuffle(astr::String, salt::String)
    len_salt = length(salt)
    len_salt == 0 && return astr

    str = copy(convert(Vector{UInt8}, astr))
    i, idx, i_sum = length(str) - 1, 0, 0
    while i > 0
        idx %= len_salt
        asc = Int(salt[idx+1])
        i_sum += asc
        j = (asc + idx + i_sum) % i
        temp = str[j+1]
        str[j+1] = str[i+1]
        str[i+1] = temp

        i = i - 1
        idx = idx + 1
    end
    return ascii(String(str))
end

function hash_num(input::Int, alphabet::String)
    alphalen = length(alphabet)
    hash = UInt8[]
    push!(hash,alphabet[(input%alphalen)+1])
    input = div(input,alphalen)
    while input > 0
        push!(hash,alphabet[(input%alphalen)+1])
        input = div(input,alphalen)
    end
    convert(String,reverse(hash))
end

function unhash_num(input::SubString{String}, alphabet::String)
    num = 0
    alphalen = length(alphabet)
    inputlen = length(input)
    for i in 1:inputlen
        pos = search(alphabet, input[i])-1
        num += pos * alphalen^(inputlen-i)
    end
    num
end

immutable Hashid
    salt::String
    min_length::Int
    alphabet::Any
    separators::Any
    guards::Any

    function Hashid(salt::String = "", min_length::Int = 0, alphabet::String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890")
        alphabet=replace(alphabet,r"\s+","")    # remove space characters
        alpha_separators = unique(intersect(alphabet, seps))
        alpha = ascii(String(setdiff(alphabet,alpha_separators)))
        if length(alpha)+length(alpha_separators) < minalphalen
            error("This algorithm requires an alphabet whose length >= $minalphalen")
        end
        if min_length < 0
            error("Minimum hash length must be >= 0")
        end
        alpha_len = length(alpha)
        sep_len = length(alpha_separators)

        alpha_separators = consistent_shuffle(ascii(String(alpha_separators)), salt)
        if alpha_separators == "" || alpha_len/sep_len > sep_div
            new_len = Int(ceil(alpha_len/sep_div))
            (new_len) == 1 && (new_len = 2)

            if new_len > sep_len
                diff = new_len - sep_len
                alpha_separators *= alpha[1:diff]
                alpha = alpha[diff+1:end]
                alpha_len = length(alpha)
            else
                alpha_separators = alpha_separators[1:new_len]
            end
        end

        alpha = consistent_shuffle(alpha, salt)
        guard_count = Int(ceil(length(alpha)/guard_div))

        if alpha_len < 3
            guards = alpha_separators[1:guard_count]
            alpha_separators = alpha_separators[guard_count+1:end]
        else
            guards = alpha[1:guard_count]
            alpha = alpha[guard_count+1:end]
        end

        new(salt, min_length, alpha, alpha_separators, guards)
    end
end

function _encode(h::Hashid, nums::Int...)
    numberHashInt = 0
    for i in 1:length(nums)
        if nums[i] < 0
            throw(DomainError())
        end
        numberHashInt += (nums[i] % (i+99))
    end
    alphabet = h.alphabet
    lottery = ret = string(alphabet[(numberHashInt % length(h.alphabet))+1])
    buffer = ""; ret_str = string(ret)
    for i in 1:length(nums)
        num = nums[i]
        buffer = lottery * h.salt * alphabet
        alphabet = consistent_shuffle(alphabet, buffer[1:length(alphabet)])
        last = hash_num(num, alphabet)
        ret_str *= last

        if i < length(nums)
            num %= Int(last[1])+i
            seps_idx = num % length(h.separators)+1
            ret_str = string(ret_str,h.separators[seps_idx])
        end
    end
    if length(ret_str) < h.min_length
        guard_idx = ((numberHashInt + Int(ret_str[1])) % length(h.guards))+1
        guard = h.guards[guard_idx]
        ret_str = string(guard,ret_str)
        if length(ret_str) < h.min_length
            guard_idx = ((numberHashInt + Int(ret_str[2])) % length(h.guards))+1
            guard = h.guards[guard_idx]
            ret_str = string(ret_str, guard)
        end
    end
    halflen = div(length(alphabet),2)
    while length(ret_str) < h.min_length
        alphabet = consistent_shuffle(alphabet, alphabet)
        ret_str = alphabet[halflen+1:end] * ret_str * alphabet[1:halflen]
        excess = length(ret_str) - h.min_length
        if excess > 0
            start = div(excess,2)
            ret_str = ret_str[start:start + h.min_length]
        end
    end
    ret_str
end

function _decode(h::Hashid, hash::String)
    ret = Int[]
    guards = Array{Char,1}(h.guards)
    separators = Array{Char,1}(h.separators)
    hash_array = split(hash, guards)
    op = ""
    alphabet = h.alphabet
    for tmp in hash_array
        op *= tmp * ", "
    end
    hash_breakdown = hash_array[2 <= length(hash_array) <= 3 ? 2 : 1]
    lottery = hash_breakdown[1]
    hash_array = split(hash_breakdown[2:end], separators)
    for sub_hash in hash_array
        buffer = string(lottery, h.salt, alphabet)
        alphabet = consistent_shuffle(alphabet, buffer[1:length(alphabet)])
        push!(ret, unhash_num(sub_hash, alphabet))
    end
    ret
end

function encode(h::Hashid, nums::Int...)
    length(nums) == 0 ? "" : _encode(h, nums...)
end

function encode(h::Hashid, nums::Vector{Int})
    _encode(h, nums...)
end

function decode(h::Hashid, e::String)
    e == "" ? Int[] : _decode(h, e)
end
