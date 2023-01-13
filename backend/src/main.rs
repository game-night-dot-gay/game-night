use axum::{
    extract::Extension,
    http::{StatusCode, Uri},
    response::IntoResponse,
    routing::{get, get_service, post},
    Router,
};

use sqlx::postgres::PgPoolOptions;
use std::time::Duration;
use std::{net::SocketAddr, sync::Arc};
use tokio::io;
use tower_http::services::{ServeDir, ServeFile};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::{prelude::*, EnvFilter};

mod api;
mod config;
mod db;
mod email;
mod telemetry;
mod token;

use crate::{
    api::{
        auth::{login_endpoint, logout_endpoint, request_login_endpoint},
        user::{current_user_endpoint, users_endpoint},
    },
    config::AppConfig,
    telemetry::init_honeycomb_tracer,
    token::SecureTokenProvider,
};
use email::SendGridEmailSender;

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    let config = AppConfig::intialize()?;

    let tracer = init_honeycomb_tracer(
        config.tracing_url.clone(),
        config.tracing_token.clone(),
        config.tracing_service.clone(),
    )?;

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
    let rng = Arc::new(SecureTokenProvider::new());

    let auth_routes = Router::new()
        .route("/request_login", post(request_login_endpoint))
        .route("/login", get(login_endpoint))
        .route("/logout", get(logout_endpoint))
        .fallback(api_fallback);

    let api_routes = Router::new()
        .route("/current_user", get(current_user_endpoint))
        .route("/users", get(users_endpoint))
        .fallback(api_fallback);

    let frontend_service =
        ServeDir::new(&frontend_dir).fallback(ServeFile::new(format!("{frontend_dir}/index.html")));

    let app = Router::new()
        .nest("/api", api_routes)
        .nest("/auth", auth_routes)
        .fallback_service(get_service(frontend_service).handle_error(handle_error))
        .layer(Extension(config))
        .layer(Extension(pool))
        .layer(Extension(email_sender))
        .layer(Extension(rng))
        .layer(tower_http::trace::TraceLayer::new_for_http());

    tracing::info!("Listening on {addr}");
    axum::Server::bind(&addr)
        .serve(app.into_make_service())
        .await?;

    Ok(())
}

async fn api_fallback(uri: Uri) -> (StatusCode, String) {
    (StatusCode::NOT_FOUND, format!("No route for {}", uri))
}

async fn handle_error(err: io::Error) -> impl IntoResponse {
    tracing::error!("Error serving frontend files: {}", err);
    (StatusCode::INTERNAL_SERVER_ERROR, "Something went wrong...")
}
