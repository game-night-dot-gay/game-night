use config::{Config, Environment, File};
use serde::Deserialize;

#[derive(Deserialize)]
pub struct AppConfig {
    pub app_domain: String,
    pub port: u16,
    pub database_url: String,
    pub frontend_dir: String,
    pub email_sender: String,
    pub email_token: String,
    pub tracing_url: String,
    pub tracing_token: String,
    pub service_name: String,
}

impl AppConfig {
    pub fn intialize() -> eyre::Result<Self> {
        let config = Config::builder()
            .set_default("port", "2727")?
            .set_default("tracing_url", "https://api.honeycomb.io")?
            .set_default("service_name", "game-night")?
            .add_source(File::with_name("app_config").required(false))
            .add_source(Environment::default().try_parsing(true))
            .build()?;

        let app_config: AppConfig = config.try_deserialize()?;
        Ok(app_config)
    }
}
