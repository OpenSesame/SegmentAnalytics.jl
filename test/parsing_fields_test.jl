using SegmentAnalytics

correct_attrs = Dict(
  :event => "Test Event",
  :properties => Dict(
    "p1" => 1,
    "p2" => 2
  ),
  :user_id => "test/id"
)

no_event_attrs = Dict(
  "properties" => Dict(
    "p1" => 1,
    "p2" => 2
  ),
  "user_id" => "test/id"
)

wrong_props_attrs = Dict(
  :event => "Test Event",
  :properties => "123",
  :user_id => "test/id"
)

wrong_timestamp_attrs = Dict(
  :event => "Test Event",
  :timestamp => "2022.01.01",
  :user_id => "test/id"
)

no_id_attrs = Dict(
  "event" => "Test Event",
  "properties" => Dict(
    "p1" => 1,
    "p2" => 2
  )
)



@testset "Testing parse_for_track" begin
  @testset "Testing with correct attrs" begin
    parsed = SegmentAnalytics.parse_for_track(correct_attrs)

    @test parsed[:type] == :track
    @test parsed[:event] == correct_attrs[:event]
    @test parsed[:userId] == correct_attrs[:user_id]
    @test haskey(parsed, :timestamp)
    @test isnothing(parsed[:messageId])
  end

  @testset "Testing with incorrect attrs" begin
    @test_throws ArgumentError SegmentAnalytics.parse_for_track(no_event_attrs)
    @test_throws ArgumentError SegmentAnalytics.parse_for_track(wrong_props_attrs)
    @test_throws ArgumentError SegmentAnalytics.parse_for_track(wrong_timestamp_attrs)
    @test_throws ArgumentError SegmentAnalytics.parse_for_track(no_id_attrs)
  end
end
