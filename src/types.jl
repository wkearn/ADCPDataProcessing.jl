export Creek

type Creek{C}
    
end

Base.string{C}(::Creek{C}) = string(C)
Base.show(io::IO,creek::Creek) = print(io,"Creek: ", string(creek))
