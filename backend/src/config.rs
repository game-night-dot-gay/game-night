use config::{Config, Environment, File};
use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct AppConfig {
    pub port: u16,
    pub database_url: String,
}

impl AppConfig {
    pub fn intialize() -> eyre::Result<Self> {
        let config = Config::builder()
            .set_default("port", "2727")?
            .add_source(File::with_name("app_config").required(false))
            .add_source(Environment::default().try_parsing(true))
            .build()?;

        let app_config: AppConfig = config.try_deserialize()?;
        Ok(app_config)
    }
}
