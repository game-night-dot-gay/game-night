use axum::headers::{HeaderMap, HeaderValue};
use base64::engine::{general_purpose::URL_SAFE, Engine};
use parking_lot::Mutex;
use rand::{Rng, SeedableRng};
use thiserror::Error;

const TOKEN_SIZE: usize = 32; // tokens should be 32 bytes long
pub const TOKEN_COOKIE: &str = "game-night-session";

pub struct Token([u8; TOKEN_SIZE]);

impl Token {
    pub fn tokens_match(&self, other: &Token) -> bool {
        constant_time_eq::constant_time_eq(&self.0, &other.0)
    }

    pub fn as_base64(&self) -> String {
        URL_SAFE.encode(self.0)
    }

    pub fn from_base64(encoded: impl AsRef<str>) -> Result<Self, InvalidTokenError> {
        let token = URL_SAFE
            .decode(encoded.as_ref())?
            .try_into()
            .map_err(|invalid: Vec<u8>| InvalidTokenError::InvalidTokenLength(invalid.len()))?;

        Ok(Self(token))
    }

    pub fn set_cookie(
        &self,
        headers: &mut HeaderMap<HeaderValue>,
    ) -> Result<(), InvalidTokenError> {
        let header_value = HeaderValue::from_str(&format!(
            "{TOKEN_COOKIE}={}; Secure; HttpOnly; SameSite=Strict; Path=/",
            self.as_base64()
        ))?;
        headers.insert("Set-Cookie", header_value);
        Ok(())
    }

    pub fn unset_cookie(headers: &mut HeaderMap<HeaderValue>) -> Result<(), InvalidTokenError> {
        let header_value = HeaderValue::from_str(&format!(
            "{TOKEN_COOKIE}=; Secure; HttpOnly; SameSite=Strict; Path=/; Expires=Thu, 01 Jan 1970 00:00:00 GMT",
        ))?;
        headers.insert("Set-Cookie", header_value);

        Ok(())
    }
}

#[derive(Debug, Error)]
pub enum InvalidTokenError {
    #[error("Could not decode token as base64")]
    Base64DecodeError(#[from] base64::DecodeError),

    #[error("Token was not the correct length: {0}")]
    InvalidTokenLength(usize),

    #[error("Token could not be converted to a header")]
    InvalidHeader(#[from] http::header::InvalidHeaderValue),
}

pub trait TokenProvider {
    fn random_token(&self) -> Token;
}

pub struct SecureTokenProvider {
    rng: Mutex<rand_chacha::ChaCha20Rng>,
}

impl SecureTokenProvider {
    pub fn new() -> Self {
        Self {
            rng: Mutex::new(rand_chacha::ChaCha20Rng::from_entropy()),
        }
    }
}

impl TokenProvider for SecureTokenProvider {
    fn random_token(&self) -> Token {
        Token(self.rng.lock().gen())
    }
}
