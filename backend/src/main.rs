use crate::config::AppConfig;
use axum::{extract::Extension, response::{Json, IntoResponse}, routing::{get, get_service}, Router, http::StatusCode};
use sqlx::postgres::{PgPool, PgPoolOptions};
use tokio::io;
use tower_http::services::ServeDir;
use std::net::SocketAddr;
use std::time::Duration;
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

mod api;
mod config;
mod db;

use db::models::User;

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    let json_layer = fmt::layer().json();
    tracing_subscriber::registry()
        .with(json_layer)
        .with(EnvFilter::from_default_env())
        .init();

    let config = AppConfig::intialize()?;

    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect_timeout(Duration::from_secs(3))
        .connect(&config.database_url)
        .await?;

    {
        let _span = tracing::info_span!("migrations");
        tracing::info!("Started migrations");

        sqlx::migrate!().run(&pool).await?;

        tracing::info!("Completed migrations");
    }

    let app = Router::new()
        .route("/api/users", get(users_endpoint))
        .fallback(get_service(ServeDir::new(config.frontend_dir)).handle_error(handle_error))
        .layer(tower_http::trace::TraceLayer::new_for_http())
        .layer(Extension(pool));

    let addr = SocketAddr::try_from(([0, 0, 0, 0], config.port))?;
    tracing::info!("Listening on {addr}");
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

async fn users_endpoint(
    Extension(pool): Extension<PgPool>,
) -> axum::response::Result<Json<Vec<User>>> {
    let users = sqlx::query_as!(User, "SELECT * FROM users")
        .fetch_all(&pool)
        .await
        .map_err(api::error::ApiError::from)?;
    Ok(Json(users))
}

async fn handle_error(_err: io::Error) -> impl IntoResponse {
    (StatusCode::INTERNAL_SERVER_ERROR, "Something went wrong...")
}
