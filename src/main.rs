use std::env::set_var;
use axum::Router;
use axum::routing::{get, post};
use lambda_http::{run, tracing, Error};
mod axum_handler;

use crate::axum_handler::{get_github_sucess, get_name, get_parameters, health_check};

#[tokio::main]
async fn main() -> Result<(), Error> {
    set_var("AWS_LAMBDA_HTTP_IGNORE_STAGE_IN_PATH", "true");

    tracing::init_default_subscriber();

    let app = Router::new()
        .route("/", get(health_check))
        .route("/health", get(health_check))
        .route("/params", post(get_parameters))
        .route("/github", get(get_github_sucess))
        .route("/hello/{name}", get(get_name));


    run(app).await
}
