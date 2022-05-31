use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Serialize)]
pub struct User {
    pub user_id: Uuid,
    pub display_name: String,
    pub pronouns: String,
    pub email: String,
    pub dietary_needs: Option<String>,
    pub is_admin: bool,
}

#[derive(Debug, Deserialize)]
pub struct InsertionUser {
    pub display_name: String,
    pub pronouns: String,
    pub email: String,
    pub dietary_needs: Option<String>,
}
