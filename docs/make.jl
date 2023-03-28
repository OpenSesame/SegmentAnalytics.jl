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

# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
#=deploydocs(
    repo = "<repository url>"
)=#
