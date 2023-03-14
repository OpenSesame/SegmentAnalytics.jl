using Test
using Dates

function log(str)
    "$(Dates.format(Dates.now(), "dd.mm.yyyy HH:MM:SS")) - $(str)\n"
end

tests = [
    "parsing_fields_test.jl",
    "transport_test.jl",
    "worker_test.jl",
    "analytics_test.jl"
]

@info log("Running tests....")
Test.@testset verbose = true showtiming = true "All tests" begin
    for test in tests
        @info log("Test: " * test)
        Test.@testset "$test" begin
            include(test)
        end
    end
end
@info log("done.")
