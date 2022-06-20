use axum::{
    extract::{self, Extension},
    http::StatusCode,
    response::{self, IntoResponse},
    routing::{get, get_service, post},
    Router,
};

use sqlx::postgres::{PgPool, PgPoolOptions};
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

use crate::{
    config::AppConfig,
    telemetry::{init_honeycomb_tracer, HoneycombConfig},
};
use db::{
    models::{InsertionUser, User},
    queries::user::{insert_user, select_all_users},
};
use email::SendGridEmailSender;

#[tokio::main]
async fn main() -> color_eyre::Result<()> {
    color_eyre::install()?;

    let config = AppConfig::intialize()?;

    let tracer = init_honeycomb_tracer(HoneycombConfig {
        endpoint: config.tracing_url.clone(),
        service_name: config.service_name.clone(),
        token: config.tracing_token.clone(),
    })?;

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
