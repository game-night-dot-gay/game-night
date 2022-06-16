use axum::{extract::Extension, response};
use sqlx::postgres::PgPool;
use tracing::instrument;

use crate::db::{models::user::User, queries::user::select_all_users};

use crate::api::auth::AuthenticatedUser;

#[instrument(skip(authenticated_user), fields(
    user.user_id = authenticated_user.user.user_id.to_string(),
    session.session_id = authenticated_user.session.session_id.to_string(),
))]
pub async fn current_user_endpoint(
    authenticated_user: AuthenticatedUser,
) -> axum::response::Result<response::Json<User>> {
    Ok(response::Json(authenticated_user.user))
}

#[instrument(skip(authenticated_user), fields(
    user.user_id = authenticated_user.user.user_id.to_string(),
    session.session_id = authenticated_user.session.session_id.to_string(),
))]
pub async fn users_endpoint(
    authenticated_user: AuthenticatedUser,
    Extension(pool): Extension<PgPool>,
) -> axum::response::Result<response::Json<Vec<User>>> {
    let users = select_all_users(&pool).await?;
    Ok(response::Json(users))
}
