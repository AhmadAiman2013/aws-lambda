use std::env::set_var;
use axum::http::header::{AUTHORIZATION, CONTENT_TYPE};
use axum::http::Method;
use axum::Router;
use axum::routing::{get, post};
use lambda_http::{run, tracing, Error};
use tower_http::cors::CorsLayer;

mod axum_handler;

use crate::axum_handler::{get_github_sucess, get_name, get_parameters, health_check};

#[tokio::main]
async fn main() -> Result<(), Error> {
    set_var("AWS_LAMBDA_HTTP_IGNORE_STAGE_IN_PATH", "true");

    tracing::init_default_subscriber();

    let origins = ["http://localhost:4200".parse()?];

    let cors = CorsLayer::new()
        .allow_origin(origins)
        .allow_methods([Method::GET, Method::POST, Method::PUT, Method::DELETE, Method::OPTIONS])
        .allow_headers([AUTHORIZATION, CONTENT_TYPE]);

    let app = Router::new()
        .route("/", get(health_check))
        .route("/health", get(health_check))
        .route("/params", post(get_parameters))
        .route("/github", get(get_github_sucess))
        .route("/hello/{name}", get(get_name))
        .layer(cors);


    run(app).await
}
