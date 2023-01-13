use sqlx::postgres::PgPool;
use tracing::instrument;

use crate::{
    api::error::ApiError,
    db::models::{
        auth::{PendingLogin, Session},
        user::User,
    },
    token::{Token, TokenProvider},
};

/// Insert login request
#[instrument(skip(token_provider))]
pub async fn create_login_request(
    pool: &PgPool,
    token_provider: &impl TokenProvider,
    user: &User,
) -> Result<PendingLogin, ApiError> {
    let login_token = token_provider.random_token().as_base64();

    let new_pending_login = sqlx::query_as!(
        PendingLogin,
        "INSERT INTO pending_logins (user_key, login_token) VALUES ($1, $2) RETURNING *",
        user.user_id,
        login_token
    )
    .fetch_one(pool)
    .await
    .map_err(crate::api::error::ApiError::from)?;

    Ok(new_pending_login)
}

/// Retrieve login request
///
/// Deletes the token if it exists
#[instrument(skip(token))]
pub async fn pending_login_for_token(
    pool: &PgPool,
    token: &Token,
) -> Result<PendingLogin, ApiError> {
    let login_token = token.as_base64();

    let pending_login = sqlx::query_as!(
        PendingLogin,
        "DELETE FROM pending_logins WHERE login_token = $1 RETURNING *",
        login_token
    )
    .fetch_one(pool)
    .await
    .map_err(crate::api::error::ApiError::from)?;

    Ok(pending_login)
}

/// Insert session
#[instrument(skip(token_provider))]
pub async fn create_session(
    pool: &PgPool,
    token_provider: &impl TokenProvider,
    pending_login: &PendingLogin,
) -> Result<Session, ApiError> {
    let session_token = token_provider.random_token().as_base64();

    let new_session = sqlx::query_as!(
        Session,
        "INSERT INTO sessions (user_key, session_token) VALUES ($1, $2) RETURNING *",
        pending_login.user_key,
        session_token
    )
    .fetch_one(pool)
    .await
    .map_err(crate::api::error::ApiError::from)?;

    Ok(new_session)
}

/// Retrieve session
#[instrument(skip(token))]
pub async fn session_for_token(pool: &PgPool, token: &Token) -> Result<Session, ApiError> {
    let session_token = token.as_base64();

    let new_session = sqlx::query_as!(
        Session,
        "SELECT * FROM sessions WHERE session_token = $1",
        session_token
    )
    .fetch_one(pool)
    .await
    .map_err(crate::api::error::ApiError::from)?;

    Ok(new_session)
}

/// Refresh session
pub async fn refresh_session(pool: &PgPool, token: &Token) -> Result<(), ApiError> {
    let session_token = token.as_base64();

    sqlx::query_as!(
        PendingLogin,
        "UPDATE sessions SET expires = DEFAULT WHERE session_token = $1",
        session_token
    )
    .execute(pool)
    .await
    .map_err(crate::api::error::ApiError::from)?;

    Ok(())
}

/// Delete session
#[instrument(skip(token))]
pub async fn delete_session(pool: &PgPool, token: &Token) -> Result<(), ApiError> {
    let session_token = token.as_base64();

    sqlx::query_as!(
        PendingLogin,
        "DELETE FROM sessions WHERE session_token = $1",
        session_token
    )
    .execute(pool)
    .await
    .map_err(crate::api::error::ApiError::from)?;

    Ok(())
}
