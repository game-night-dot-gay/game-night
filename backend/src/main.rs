use crate::config::AppConfig;
use axum::{response::Json, routing::get, Router};
use serde_json::json;
use std::net::SocketAddr;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

mod config;

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;
    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(EnvFilter::from_default_env())
        .init();

    let config = AppConfig::intialize()?;

    let app = Router::new()
        .route("/", get(|| async { Json(json!({"data": 42})) }))
        .layer(tower_http::trace::TraceLayer::new_for_http());

    let addr = SocketAddr::try_from(([0, 0, 0, 0], config.port))?;
    tracing::info!("Listening on {addr}");
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}
