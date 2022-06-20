use ammonia::Url;
use opentelemetry::{
    sdk::{self, trace, Resource},
    KeyValue,
};
use opentelemetry_otlp::WithExportConfig;
use tonic::{metadata::MetadataMap, transport::ClientTlsConfig};

pub struct HoneycombConfig {
    pub endpoint: String,
    pub service_name: String,
    pub token: String,
}

pub fn init_honeycomb_tracer(config: HoneycombConfig) -> eyre::Result<sdk::trace::Tracer> {
    let mut map = MetadataMap::with_capacity(1);

    map.insert("x-honeycomb-team", config.token.parse()?);

    let endpoint = Url::parse(&config.endpoint)?;

    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .tonic()
                .with_endpoint(&config.endpoint)
                .with_metadata(map)
                .with_tls_config(
                    ClientTlsConfig::new().domain_name(
                        endpoint
                            .host_str()
                            .expect("the specified endpoint should have a valid hostname"),
                    ),
                ),
        )
        .with_trace_config(
            trace::config().with_resource(Resource::new(vec![KeyValue::new(
                "service.name",
                config.service_name,
            )])),
        )
        .install_batch(opentelemetry::runtime::Tokio)?;

    Ok(tracer)
}
