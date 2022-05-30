use sqlx::postgres::PgPool;

use crate::{
    api::error::ApiError,
    db::models::User,
    db::{input_sanitization::sanitize, models::InsertionUser},
};

/// Select all users
pub async fn select_all_users(pool: &PgPool) -> Result<Vec<User>, ApiError> {
    let users = sqlx::query_as!(User, "SELECT * FROM users")
        .fetch_all(pool)
        .await
        .map_err(crate::api::error::ApiError::from)?;
    Ok(users)
}

/// Insert a new user
pub async fn insert_user(pool: &PgPool, new_user: InsertionUser) -> Result<User, ApiError> {
    let new_user = sqlx::query_as!(
        User,
        "INSERT INTO users (display_name, pronouns) VALUES ($1, $2) RETURNING *",
        sanitize(&new_user.display_name),
        sanitize(&new_user.pronouns)
    )
    .fetch_one(pool)
    .await
    .map_err(crate::api::error::ApiError::from)?;

    Ok(new_user)
}
