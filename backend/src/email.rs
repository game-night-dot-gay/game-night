use std::fmt::Debug;

use crate::config::AppConfig;
use askama::Template;
use async_trait::async_trait;
use sendgrid::{Mail, SGClient};

#[async_trait]
pub trait EmailSender {
    async fn send_email<T>(
        &self,
        to_email: String,
        to_name: String,
        body: T,
    ) -> Result<(), EmailError>
    where
        T: AsMail + Send + std::fmt::Debug;
}

#[derive(Clone)]
pub struct SendGridEmailSender {
    email_sender: String,
    client: SGClient,
}

impl SendGridEmailSender {
    pub fn new(app_config: &AppConfig) -> Self {
        Self {
            email_sender: app_config.email_sender.to_string(),
            client: SGClient::new(&app_config.email_token),
        }
    }
}

impl Debug for SendGridEmailSender {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("SendGridEmailSender")
            .field("email_sender", &self.email_sender)
            // prevent the client from being logged with the email token
            .field("client", &"<client>")
            .finish()
    }
}

#[async_trait]
impl EmailSender for SendGridEmailSender {
    #[tracing::instrument]
    async fn send_email<T>(
        &self,
        to_email: String,
        to_name: String,
        template: T,
    ) -> Result<(), EmailError>
    where
        T: AsMail + Send + std::fmt::Debug,
    {
        let subject = template.subject()?;
        let body = template.body()?;
        let mail = Mail::new()
            .add_from(&self.email_sender)
            .add_to((to_email.as_str(), to_name.as_str()).into())
            .add_subject(&subject)
            .add_html(&body);

        self.client
            .send(mail)
            .await
            .map_err(EmailError::SendGridError)?;
        tracing::debug!("Sent email via SendGrid");

        Ok(())
    }
}

pub enum EmailError {
    TemplateRenderError(askama::Error),
    SendGridError(sendgrid::SendgridError),
}

pub trait AsMail {
    fn subject(&self) -> Result<String, EmailError>;
    fn body(&self) -> Result<String, EmailError>;
    fn text_fallback(&self) -> Result<String, EmailError>;
}

#[derive(Debug, Template)]
#[template(path = "login.html")]
pub struct LoginEmail {
    pub app_domain: String,
    pub magic_token: String,
}

impl AsMail for LoginEmail {
    fn subject(&self) -> Result<String, EmailError> {
        Ok("Log in to GameNight".to_string())
    }

    fn body(&self) -> Result<String, EmailError> {
        self.render().map_err(EmailError::TemplateRenderError)
    }

    fn text_fallback(&self) -> Result<String, EmailError> {
        Ok(format!(
            "Log in: https://{}/login?token={}",
            self.app_domain, self.magic_token
        ))
    }
}
