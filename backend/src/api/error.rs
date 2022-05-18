use axum::{
    http::StatusCode,
    response::{IntoResponse, Json},
};
use serde::Serialize;

use crate::email::EmailError;

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

impl From<EmailError> for ApiError {
    fn from(e: EmailError) -> Self {
        match e {
            EmailError::TemplateRenderError(tre) => Self {
                message: format!("Email template error: {tre}"),
            },
            EmailError::SendGridError(sg) => Self {
                message: format!("Email error: {sg}"),
            },
        }
    }
}
