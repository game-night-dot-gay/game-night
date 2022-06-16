use sqlx::postgres::PgPool;
use tracing::instrument;
use uuid::Uuid;

use crate::{
    api::error::ApiError,
    db::input_sanitization::sanitize,
    db::models::user::{InsertionUser, User},
};

/// Select all users
#[instrument]
pub async fn select_all_users(pool: &PgPool) -> Result<Vec<User>, ApiError> {
    let users = sqlx::query_as!(User, "SELECT * FROM users")
        .fetch_all(pool)
        .await
        .map_err(crate::api::error::ApiError::from)?;
    Ok(users)
}

/// Get the user via id
#[instrument]
pub async fn user_by_id(pool: &PgPool, user_id: &Uuid) -> Result<User, ApiError> {
    let user = sqlx::query_as!(User, "SELECT * FROM users where user_id = $1", user_id)
        .fetch_one(pool)
        .await
        .map_err(crate::api::error::ApiError::from)?;
    Ok(user)
}

/// Get the user via email
#[instrument]
pub async fn user_by_email(pool: &PgPool, email: &str) -> Result<User, ApiError> {
    let user = sqlx::query_as!(User, "SELECT * FROM users where email = $1", email)
        .fetch_one(pool)
        .await
        .map_err(crate::api::error::ApiError::from)?;
    Ok(user)
}

/// Insert a new user
#[instrument]
pub async fn insert_user(pool: &PgPool, new_user: InsertionUser) -> Result<User, ApiError> {
    let new_user = sqlx::query_as!(
        User,
        "INSERT INTO users (display_name, pronouns, email, dietary_needs) VALUES ($1, $2, $3, $4) RETURNING *",
        sanitize(&new_user.display_name),
        sanitize(&new_user.pronouns),
        sanitize(&new_user.email),
        new_user.dietary_needs.map(sanitize),
    )
    .fetch_one(pool)
    .await
    .map_err(crate::api::error::ApiError::from)?;

    Ok(new_user)
}
