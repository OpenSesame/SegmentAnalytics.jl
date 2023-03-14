using SegmentAnalytics
using Mocking

Mocking.activate()

options = Dict(
  "write_key" => "test"
)

@testset "Testing analytics initialization" begin
  analytics = SegmentAnalytics.Analytics(options)

  @test analytics.write_key == options["write_key"]
  @test isempty(analytics.queue)
end

@testset "Testing analytics track" begin
  runworker_patch = @patch SegmentAnalytics.runworker(args...) = "Test"
  analytics = SegmentAnalytics.Analytics(options)

  payload = Dict(
    "event" => "Test Event",
    "user_id" => "test/id",
    "properties" => Dict("p1" => 1, "p2" => 2)
  )

  track(analytics, payload)

  @test length(analytics.queue) == 1
  @test !isnothing(analytics.worker_task)
end
