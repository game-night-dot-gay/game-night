use ammonia::Url;
use eyre::eyre;
use opentelemetry::{
    sdk::{self, trace, Resource},
    KeyValue,
};
use opentelemetry_otlp::WithExportConfig;
use tonic::{metadata::MetadataMap, transport::ClientTlsConfig};

pub fn init_honeycomb_tracer(
    endpoint: String,
    token: String,
    service_name: String,
) -> eyre::Result<sdk::trace::Tracer> {
    let mut map = MetadataMap::with_capacity(1);

    map.insert("x-honeycomb-team", token.parse()?);

    let endpoint = Url::parse(&endpoint)?;

    let domain_name = endpoint
        .host_str()
        .ok_or_else(|| eyre!("the specified endpoint should have a valid hostname"))?;

    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .tonic()
                .with_endpoint(endpoint.as_str())
                .with_metadata(map)
                .with_tls_config(ClientTlsConfig::new().domain_name(domain_name)),
        )
        .with_trace_config(
            trace::config().with_resource(Resource::new(vec![KeyValue::new(
                "service.name",
                service_name,
            )])),
        )
        .install_batch(opentelemetry::runtime::Tokio)?;

    Ok(tracer)
}
