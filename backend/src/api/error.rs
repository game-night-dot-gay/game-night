use axum::{
    http::StatusCode,
    response::{IntoResponse, Json},
};
use serde::Serialize;

use crate::{email::EmailError, token::InvalidTokenError};

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
        tracing::error!("Database error: {e}");
        Self {
            message: format!("Database error: {e}"),
        }
    }
}

impl From<EmailError> for ApiError {
    fn from(e: EmailError) -> Self {
        let message = match e {
            EmailError::TemplateRenderError(tre) => format!("Email template error: {tre}"),

            EmailError::SendGridError(sg) => format!("Email error: {sg}"),
        };

        tracing::error!("EmailError {message}");

        Self { message }
    }
}

impl From<InvalidTokenError> for ApiError {
    fn from(e: InvalidTokenError) -> Self {
        tracing::error!("Token error: {e}");
        Self {
            message: format!("Token error: {e}"),
        }
    }
}
