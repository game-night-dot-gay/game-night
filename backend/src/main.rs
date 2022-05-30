use axum::{
    extract::Extension,
    http::StatusCode,
    response::{IntoResponse, Json},
    routing::{get, get_service},
    Router,
};
use sqlx::postgres::{PgPool, PgPoolOptions};
use std::time::Duration;
use std::{net::SocketAddr, sync::Arc};
use tokio::io;
use tower_http::services::{ServeDir, ServeFile};
use tracing_subscriber::{fmt, prelude::*, EnvFilter};

mod api;
mod config;
mod db;
mod email;

use crate::config::AppConfig;
use db::models::User;
use email::SendGridEmailSender;

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
