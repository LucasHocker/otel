require 'opentelemetry/sdk'
require 'opentelemetry/common/utilities'
require 'opentelemetry/exporter/otlp'
Bundler.require
puts "otel.rb starting tracing..."

## Define a reporter so we have some idea why if span export fails
class MyMetricsReporter
          def add_to_counter(metric, increment: 1, labels: {})
            puts "otel.rb - Reporter: " + metric + labels.inspect
          end

          def record_value(metric, value:, labels: {})
            puts "otel.rb - Reporter: " + metric + labels.inspect
          end

          def observe_value(metric, value:, labels: {}); end
end
reporter = MyMetricsReporter.new();


## Define our exporter, note format for handling of headers. Still unclear on format if using env OTEL_EXPORTER_OTLP_HEADERS
## Also note: 'v1/traces' needs to be added if endpoint is specified in code. Must NOT be added if done via env OTEL_EXPORTER_OTLP_ENDPOINT
headers = Hash["Authorization" => "Api-Token dt0c01.XXXXXXXXXXX"]
dtexporter = OpenTelemetry::Exporter::OTLP::Exporter.new(
            endpoint: 'https://XXXXXXXX.sprint.dynatracelabs.com/api/v2/otlp/v1/traces',
            headers: headers,
            metrics_reporter: reporter
         )

# Just for sanity, validate our exporter before trying to use below. Was helpful in figuring out endpoint and header formats
dtexportervalid = OpenTelemetry::Common::Utilities.valid_exporter?(dtexporter)
if dtexportervalid
  puts "otel.rb - valid exporter"
else 
  puts "otel.rb - invalid exporter"
  puts dtexporter
end

# Actually configure everything
# Use the ConsoleSpanExporter if you're having trouble with instrumentation and need to see the spans. It comes with a substantial performance penalty!
OpenTelemetry::SDK.configure do |c|
   c.use_all
#   c.add_span_processor(
#     OpenTelemetry::SDK::Trace::Export::SimpleSpanProcessor.new(
#      OpenTelemetry::SDK::Trace::Export::ConsoleSpanExporter.new
#     )
#   )
   c.add_span_processor(
       OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
         dtexporter
       )
   )
end


# send a test tracer for application startup
# Note: you'll see this on console if ConsoleSpanExporter enabled but will not in DT
tracer = OpenTelemetry.tracer_provider.tracer('Dynatrace', '0.1.0')

# create a span
tracer.in_span('App_startup') do |span|
  # set an attribute
  span.set_attribute('file', 'otel.rb')
  # add an event
  span.add_event('App Instrumented')
end
# Include a little output, just to confirm you actually ran this file.
puts "otel.rb was run"
