use serde::Serialize;
use std::fmt::Debug;
use time::OffsetDateTime;
use uuid::Uuid;

#[derive(Serialize)]
pub struct PendingLogin {
    pub login_id: Uuid,
    pub user_key: Uuid,
    pub login_token: String,
    pub expires: OffsetDateTime,
}

impl Debug for PendingLogin {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("PendingLogin")
            .field("login_id", &self.login_id)
            .field("user_key", &self.user_key)
            .field("expires", &self.expires)
            .finish()
    }
}

#[derive(Serialize)]
pub struct Session {
    pub session_id: Uuid,
    pub user_key: Uuid,
    pub session_token: String,
    pub expires: OffsetDateTime,
}

impl Debug for Session {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Session")
            .field("session_id", &self.session_id)
            .field("user_key", &self.user_key)
            .field("expires", &self.expires)
            .finish()
    }
}
