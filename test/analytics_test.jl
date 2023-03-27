using SegmentAnalytics
using Mocking

Mocking.activate()

write_key = "test"

@testset "Testing analytics initialization" begin
  analytics = SegmentAnalytics.Analytics(write_key=write_key)

  @test analytics.write_key == write_key
  @test isempty(analytics.queue)
end

@testset "Testing analytics track" begin
  runworker_patch = @patch SegmentAnalytics.runworker(args...) = "Test"
  analytics = SegmentAnalytics.Analytics(write_key=write_key)

  payload = Dict(
    :event => "Test Event",
    :user_id => "test/id",
    :properties => Dict("p1" => 1, "p2" => 2)
  )

  apply(runworker_patch) do 
    track(analytics, payload)
  end
  
  @test length(analytics.queue) == 1
  @test !isnothing(analytics.worker_task)
end
