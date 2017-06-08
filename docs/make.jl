using Documenter, ADCPDataProcessing

makedocs()

deploydocs(
    deps = Deps.pip("mkdocs"),
    repo = "github.com/wkearn/ADCPDataProcessing.jl.git",
    julia = "0.6"
)
