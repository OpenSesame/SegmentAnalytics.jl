using SegmentAnalytics
using DataStructures
using Mocking
using HTTP

Mocking.activate()

write_key = "test"
queue = Queue{Dict}()
options = Dict(
  "batch_size" => 5
)

@testset "Testing worker initialization" begin
  worker = SegmentAnalytics.Worker(queue, write_key, options)

  @test worker.batch_size == options["batch_size"]
end

successful_transport_mock = HTTP.Response(200, Dict("success" => true))
unsuccessful_transport_mock = HTTP.Response(500, "Server Error")

test_message = Dict(
  "type" => "track",
  "event" => "test_event",
  "properties" => Dict("p1" => 1, "p2" => 2)
)

messages_count = options["batch_size"] * 2 + 1

@testset "Testing run worker" begin
  @testset "Testing worker with successful response" begin
    successful_responses = []

    transport_patch = @patch(
      SegmentAnalytics.send(::SegmentAnalytics.Transport, ::String, ::SegmentAnalytics.MessageBatch) = begin
        push!(successful_responses, successful_transport_mock)

        successful_transport_mock
      end
    )

    worker = SegmentAnalytics.Worker(queue, write_key, options)
    foreach(_ -> enqueue!(worker.queue, test_message), 1:messages_count)

    apply(transport_patch) do
      SegmentAnalytics.runworker(worker)

      @test isempty(worker.queue)
      @test length(successful_responses) == 3
    end
  end

  @testset "Testing with unsuccessful response and custom error handler" begin
    global errors_count = 0
    options_with_on_error = Dict(
      "batch_size" => 5,
      "on_error" => (status, error) -> global errors_count += 1
    )

    transport_patch = @patch(
      SegmentAnalytics.send(::SegmentAnalytics.Transport, ::String, ::SegmentAnalytics.MessageBatch) =
        unsuccessful_transport_mock
    )

    worker = SegmentAnalytics.Worker(queue, write_key, options_with_on_error)
    foreach(_ -> enqueue!(worker.queue, test_message), 1:messages_count)

    apply(transport_patch) do
      SegmentAnalytics.runworker(worker)

      @test errors_count == 3
    end
  end
end
