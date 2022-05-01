use crate::config::AppConfig;
use axum::{response::Json, routing::get, Router};
use serde_json::json;
use std::net::SocketAddr;

mod config;

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    let config = AppConfig::intialize()?;

    let app = Router::new().route("/", get(|| async { Json(json!({"data": 42})) }));

    let addr = SocketAddr::try_from(([0, 0, 0, 0], config.port))?;
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}
