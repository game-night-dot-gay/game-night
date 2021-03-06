use config::{Config, Environment, File};
use serde::Deserialize;

#[derive(Deserialize)]
pub struct AppConfig {
    pub app_base_url: String,
    pub port: u16,
    pub database_url: String,
    pub frontend_dir: String,
    pub sender_email: String,
    pub sender_name: String,
    pub email_token: String,
    pub tracing_url: String,
    pub tracing_token: String,
    pub tracing_service: String,
}

impl AppConfig {
    pub fn intialize() -> eyre::Result<Self> {
        let config = Config::builder()
            .set_default("port", "2727")?
            .set_default("tracing_url", "https://api.honeycomb.io")?
            .set_default("tracing_service", "game-night")?
            .add_source(File::with_name("app_config").required(false))
            .add_source(Environment::default().try_parsing(true))
            .build()?;

        let app_config: AppConfig = config.try_deserialize()?;
        Ok(app_config)
    }
}
