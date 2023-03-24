module SegmentAnalytics

export track

include("version.jl")
include("utils.jl")
include("parsing_fields.jl")
include("backoff_policy.jl")
include("message_batch.jl")
include("transport.jl")
include("worker.jl")
include("analytics.jl")

end # module SegmentAnalytics
