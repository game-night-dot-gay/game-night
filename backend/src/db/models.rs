use serde::Serialize;
use uuid::Uuid;

#[derive(Debug, Serialize)]
pub struct User {
    pub user_id: Uuid,
    pub display_name: String,
    pub pronouns: String,
}
