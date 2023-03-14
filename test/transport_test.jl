using SegmentAnalytics
using HTTP
using Mocking
using JSON

Mocking.activate()

options = Dict(
  "port" => 80,
  "host" => "test.com",
  "retries" => 2
)

write_key = "testkey"

@testset "Testing initialize transport" begin
  transport = SegmentAnalytics.Transport(options)

  @test transport.host == options["host"]
  @test transport.port == options["port"]
  @test transport.path == SegmentAnalytics.DEFAULT_PATH
end

successful_http_response = HTTP.Response(200, JSON.json(Dict("success" => true)))
unsuccessful_http_response = HTTP.Response(500, JSON.json(Dict("error" => "Some error")))

test_message = Dict(
  "type" => "track",
  "event" => "test_event",
  "properties" => Dict("p1" => 1, "p2" => 2)
)

@testset "Testing successful response to segment" begin
  sent_payloads = []
  http_post_patch = @patch(
    HTTP.post(args...; kwargs...) = begin
      push!(sent_payloads, kwargs[:body])

      successful_http_response
    end
  )

  transport = SegmentAnalytics.Transport(options)
  batch = SegmentAnalytics.MessageBatch(5)

  SegmentAnalytics.push!(batch, test_message)

  apply(http_post_patch) do
    res = SegmentAnalytics.send(transport, write_key, batch)

    sent_payload = first(sent_payloads) |> JSON.parse

    @test res.status == 200
    @test haskey(sent_payload, "sentAt")
    @test haskey(sent_payload, "batch")
    @test JSON.parse(sent_payload["batch"][begin])["event"] == "test_event"
  end
end

@testset "Testing unsuccessful response to segment" begin
  http_post_patch = @patch HTTP.post(args...; kwargs...) = unsuccessful_http_response

  transport = SegmentAnalytics.Transport(options)
  batch = SegmentAnalytics.MessageBatch(5)

  SegmentAnalytics.push!(batch, test_message)

  apply(http_post_patch) do
    res = SegmentAnalytics.send(transport, write_key, batch)

    @test res.status == 500
  end
end
