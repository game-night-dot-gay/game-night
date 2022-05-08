use axum::{
    http::StatusCode,
    response::{IntoResponse, Json},
};
use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct ApiError {
    pub message: String,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> axum::response::Response {
        (StatusCode::BAD_REQUEST, Json(self)).into_response()
    }
}

impl From<sqlx::error::Error> for ApiError {
    fn from(e: sqlx::error::Error) -> Self {
        Self {
            message: format!("Database error: {e}"),
        }
    }
}
