use axum::{
    async_trait,
    extract::{self, Extension, FromRequestParts, Query},
    headers::Cookie,
    http::{request::Parts, StatusCode},
    response::{self, IntoResponse},
    TypedHeader,
};
use serde::Deserialize;
use sqlx::postgres::PgPool;
use sqlx::types::time::OffsetDateTime;
use std::cmp::Ordering;
use std::sync::Arc;
use tracing::instrument;

use crate::db::{
    models::auth::Session,
    queries::{
        auth::{delete_session, session_for_token},
        user::{self, user_by_id},
    },
};
use crate::db::{
    models::user::User,
    queries::auth::{create_login_request, create_session, pending_login_for_token},
};
use crate::email::{EmailSender, LoginEmail, SendGridEmailSender};
use crate::token::{SecureTokenProvider, Token, TokenProvider};
use crate::{config::AppConfig, token::TOKEN_COOKIE};

use super::error::ApiError;

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    email: String,
}

#[instrument(skip(config, token_provider))]
pub async fn request_login_endpoint(
    config: Extension<Arc<AppConfig>>,
    Extension(pool): Extension<PgPool>,
    token_provider: Extension<Arc<SecureTokenProvider>>,
    Extension(email_sender): Extension<SendGridEmailSender>,
    extract::Json(email): extract::Json<LoginRequest>,
) -> Result<StatusCode, ApiError> {
    let Extension(config) = config;
    let Extension(token_provider) = token_provider;

    let outcome = request_login(config, pool, token_provider, email_sender, &email).await;
    match outcome {
        Ok(()) => tracing::trace!("Requested login for email {}", email.email),
        Err(e) => tracing::error!("Could not get user for email {}: {:?}", email.email, e),
    }

    Ok(StatusCode::OK)
}

async fn request_login(
    config: Arc<AppConfig>,
    pool: PgPool,
    token_provider: Arc<impl TokenProvider>,
    email_sender: SendGridEmailSender,
    email: &LoginRequest,
) -> Result<(), ApiError> {
    let user = user::user_by_email(&pool, &email.email).await?;
    let pending_login = create_login_request(&pool, token_provider.as_ref(), &user).await?;

    let login_email = LoginEmail {
        app_base_url: config.app_base_url.to_string(),
        login_token: pending_login.login_token,
    };
    email_sender
        .send_email(user.email, user.display_name, login_email)
        .await?;
    Ok(())
}

#[derive(Debug, Deserialize)]
pub struct LoginQuery {
    token: String,
    redirect_url: Option<String>,
}

#[instrument(skip(token_provider))]
pub async fn login_endpoint(
    Extension(pool): Extension<PgPool>,
    token_provider: Extension<Arc<SecureTokenProvider>>,
    Query(login_query): Query<LoginQuery>,
) -> response::Result<response::Response> {
    let Extension(token_provider) = token_provider;
    let pending_login_token = Token::from_base64(login_query.token).map_err(ApiError::from)?;
    let pending_login = pending_login_for_token(&pool, &pending_login_token).await?;
    tracing::trace!("Found pending login for {}", pending_login.user_key);

    let now = OffsetDateTime::now_utc();
    if now.cmp(&pending_login.expires) == Ordering::Greater {
        tracing::debug!("Pending login expired for {}", pending_login.user_key);
        return Err(ApiError {
            message: format!("Pending login expired"),
        }
        .into());
    }

    let session = create_session(&pool, token_provider.as_ref(), &pending_login).await?;
    tracing::trace!("Created session for {}", session.user_key);

    let session_token = Token::from_base64(session.session_token).map_err(ApiError::from)?;

    let redirect_url = login_query.redirect_url.unwrap_or("/".to_string());
    let mut redirect = response::Redirect::to(&redirect_url).into_response();
    session_token
        .set_cookie(redirect.headers_mut())
        .map_err(ApiError::from)?;
    tracing::trace!("Set session token header for {}", session.user_key);

    Ok(redirect)
}

#[instrument]
pub async fn logout_endpoint(
    authenticated_user: AuthenticatedUser,
    Extension(pool): Extension<PgPool>,
) -> axum::response::Result<response::Response> {
    let token =
        Token::from_base64(authenticated_user.session.session_token).map_err(ApiError::from)?;
    delete_session(&pool, &token).await?;

    let mut redirect = response::Redirect::to("/login").into_response();
    Token::unset_cookie(redirect.headers_mut()).map_err(ApiError::from)?;

    Ok(redirect)
}

#[derive(Debug)]
pub struct AuthenticatedUser {
    pub user: User,
    pub session: Session,
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthenticatedUser
where
    S: Send + Sync,
{
    type Rejection = StatusCode;

    async fn from_request_parts(parts: &mut Parts, state: &S) -> Result<Self, Self::Rejection> {
        let cookie = Option::<TypedHeader<Cookie>>::from_request_parts(parts, state)
            .await
            .map_err(|e| {
                tracing::error!("Failed to get cookie header: {e}");
                StatusCode::UNAUTHORIZED
            })?;

        let token_cookie = cookie.as_ref().and_then(|cookie| cookie.get(TOKEN_COOKIE));

        if let Some(token_cookie) = token_cookie {
            tracing::trace!("Got cookie {token_cookie}");

            let token = Token::from_base64(token_cookie).map_err(|e| {
                tracing::error!("Failed to process token: {e}");
                StatusCode::UNAUTHORIZED
            })?;

            let Extension(pool): Extension<PgPool> = Extension::from_request_parts(parts, state)
                .await
                .map_err(|e| {
                    tracing::error!("Could not get the postgres pool: {e}");
                    StatusCode::INTERNAL_SERVER_ERROR
                })?;

            let session = session_for_token(&pool, &token).await.map_err(|e| {
                tracing::error!("Failed to get session: {}", e.message);
                StatusCode::UNAUTHORIZED
            })?;

            let now = OffsetDateTime::now_utc();
            if now.cmp(&session.expires) == Ordering::Greater {
                tracing::debug!("Session expired for {}", session.user_key);
                return Err(StatusCode::UNAUTHORIZED);
            } else {
                // TODO: extend session?
            }

            let user = user_by_id(&pool, &session.user_key).await.map_err(|e| {
                tracing::error!("Failed to get user: {}", e.message);
                StatusCode::UNAUTHORIZED
            })?;

            Ok(Self { user, session })
        } else {
            tracing::error!("No cookie present for request {}", parts.uri);
            Err(StatusCode::UNAUTHORIZED)
        }
    }
}
