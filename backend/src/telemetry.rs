

pub enum TelemetryBackend {
    StdOut,
    Honeycomb
}

pub struct TracingSubscriber {
    backend: TelemetryBackend,

}