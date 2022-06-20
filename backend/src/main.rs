use ammonia::Url;
use axum::{
    extract::{self, Extension},
    http::StatusCode,
    response::{self, IntoResponse},
    routing::{get, get_service, post},
    Router,
};
use opentelemetry::{
    sdk::{trace, Resource},
    trace::Tracer,
    KeyValue,
};
use opentelemetry_otlp::WithExportConfig;
use sqlx::postgres::{PgPool, PgPoolOptions};
use std::time::Duration;
use std::{net::SocketAddr, sync::Arc};
use tokio::io;
use tonic::{metadata::MetadataMap, transport::ClientTlsConfig};
use tower_http::services::{ServeDir, ServeFile};
use tracing::{error, span};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::Registry;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

mod api;
mod config;
mod db;
mod email;
mod telemetry;

use crate::config::AppConfig;
use db::{
    models::{InsertionUser, User},
    queries::user::{insert_user, select_all_users},
};
use email::SendGridEmailSender;

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    let config = AppConfig::intialize()?;

    let mut map = MetadataMap::with_capacity(1);

    map.insert("x-honeycomb-team", config.tracing_token.parse()?);

    let endpoint = Url::parse(&config.tracing_url)?;

    let tracer = opentelemetry_otlp::new_pipeline()
        .tracing()
        .with_exporter(
            opentelemetry_otlp::new_exporter()
                .tonic()
                .with_endpoint(&config.tracing_url)
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
                "game-night",
            )])),
        )
        .install_batch(opentelemetry::runtime::Tokio)?;

    let telemetry = tracing_opentelemetry::layer().with_tracer(tracer);

    tracing_subscriber::registry()
        .with(telemetry)
        .with(EnvFilter::from_default_env())
        .init();

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .acquire_timeout(Duration::from_secs(3))
        .connect(&config.database_url)
        .await?;

    {
        let _span = tracing::info_span!("migrations");
        tracing::info!("Started migrations");

        sqlx::migrate!().run(&pool).await?;

        tracing::info!("Completed migrations");
    }
    let email_sender = SendGridEmailSender::new(&config);

    let addr = SocketAddr::try_from(([0, 0, 0, 0], config.port))?;

    let frontend_dir = config.frontend_dir.clone();
    let config = Arc::new(config);

    let api_routes = Router::new()
        .route("/users", get(users_endpoint))
        .layer(Extension(config))
        .layer(Extension(pool))
        .layer(Extension(email_sender));

    let frontend_service =
        ServeDir::new(&frontend_dir).fallback(ServeFile::new(format!("{frontend_dir}/index.html")));

    let app = Router::new()
        .nest("/api", api_routes)
        .fallback(get_service(frontend_service).handle_error(handle_error))
        .layer(tower_http::trace::TraceLayer::new_for_http());

    tracing::info!("Listening on {addr}");
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

async fn users_endpoint(
    Extension(pool): Extension<PgPool>,
) -> axum::response::Result<response::Json<Vec<User>>> {
    let users = select_all_users(&pool).await?;
    Ok(response::Json(users))
}

async fn handle_error(_err: io::Error) -> impl IntoResponse {
    (StatusCode::INTERNAL_SERVER_ERROR, "Something went wrong...")
}
