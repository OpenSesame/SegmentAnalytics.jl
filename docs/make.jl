using Documenter
using SegmentAnalytics

makedocs(
    sitename = "SegmentAnalytics",
    format = Documenter.HTML(),
    modules = [SegmentAnalytics],
    pages=[
        "Home" => "index.md",
        "API" => [
            "Analytics" => "API/analytics.md"
        ]
    ]
)

deploydocs(repo = "github.com/OpenSesame/SegmentAnalytics.jl.git")
